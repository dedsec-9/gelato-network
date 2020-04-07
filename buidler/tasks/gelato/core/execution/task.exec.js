import { task, types } from "@nomiclabs/buidler/config";
import { defaultNetwork } from "../../../../../buidler.config";
import { utils } from "ethers";

export default task(
  "gc-exec",
  `Calls GelatoCore.exec() on [--network] (default: ${defaultNetwork})`
)
  .addPositionalParam("execclaimid")
  .addOptionalPositionalParam(
    "executorindex",
    "Which mnemonic index should be selected for gelatoExecutor msg.sender (default index 1)",
    1,
    types.int
  )
  .addOptionalParam("execclaim", "Supply LogExecClaimMinted values in an obj")
  .addOptionalParam(
    "fromblock",
    "The block number to search for event logs from",
    undefined, // default
    types.number
  )
  .addOptionalParam(
    "toblock",
    "The block number up until which to look for",
    undefined, // default
    types.number
  )
  .addOptionalParam("blockhash", "Search a specific block")
  .addOptionalParam("txhash", "Filter for a specific tx")
  .addFlag("log", "Logs return values to stdout")
  .setAction(
    async ({
      execclaimid,
      executorindex,
      execclaim,
      fromblock,
      toblock,
      blockhash,
      txhash,
      log,
    }) => {
      try {
        if (!execclaim) {
          execclaim = await run("fetchExecClaim", {
            execclaimid,
            execclaim,
            fromblock,
            toblock,
            blockhash,
            txhash,
            log,
          });
        }

        const { [executorindex]: gelatoExecutor } = await ethers.getSigners();

        const gelatoCore = await run("instantiateContract", {
          contractname: "GelatoCore",
          signer: gelatoExecutor,
          write: true,
        });

        let gelatoGasPrice;
        try {
          gelatoGasPrice = await gelatoCore.gelatoGasPrice();
        } catch (error) {
          console.log("Using default gas price of 9 gwei");
          gelatoGasPrice = utils.parseUnits("9", "gwei");
        }

        const gelatoGasPriceGwei = utils.formatUnits(gelatoGasPrice, "gwei");
        let gelatoMAXGAS;
        try {
          gelatoMAXGAS = await gelatoCore.gelatoMaxGas();
        } catch (error) {
          console.error(`gelatoCore.MAXGAS() error\n`, error);
        }

        if (log) {
          console.log(
            `\n Gelato Gas Price:  ${gelatoGasPriceGwei} gwei\
             \n Gelato MAX GAS:    ${gelatoMAXGAS}\
             \n UserProxy Address: ${execclaim[3]}\n
             \n Executor Address: ${gelatoExecutor._address}\n`
          );
        }

        const execClaim = {
          id: execclaim[0],
          provider: execclaim[1],
          providerModule: execclaim[2],
          userProxy: execclaim[3],
          condition: execclaim[4],
          action: execclaim[5],
          conditionPayload: execclaim[6],
          actionPayload: execclaim[7],
          expiryDate: execclaim[8],
        };

        let executeTx;
        try {
          executeTx = await gelatoCore.exec(execClaim, {
            gasPrice: gelatoGasPrice,
            gasLimit: gelatoMAXGAS,
          });
        } catch (error) {
          console.error(`gelatoCore.exec() PRE-EXECUTION error\n`, error);
        }

        if (log) console.log(`\ntxHash execTransaction: ${executeTx.hash}\n`);

        let executeTxReceipt;
        try {
          executeTxReceipt = await executeTx.wait();
        } catch (error) {
          console.error(`gelatoCore.exec() EXECUTION error\n`, error);
        }

        if (executeTxReceipt && log) {
          const eventNames = [
            "LogCanExecSuccess",
            "LogCanExecFailed",
            "LogExecSuccess",
            "LogExecFailed",
          ];

          const executionEvents = [];

          for (const eventname of eventNames) {
            const executionEvent = await run("event-getparsedlog", {
              contractname: "GelatoCore",
              eventname,
              txhash: executeTxReceipt.transactionHash,
              blockhash: executeTxReceipt.blockHash,
              values: true,
              stringify: true,
            });
            if (executionEvent)
              executionEvents.push({ [eventname]: executionEvent });
          }
          console.log(
            `\nExecution Events emitted for exec-tx: ${executeTx.hash}:`
          );
          for (const event of executionEvents) console.log(event);
        }

        return executeTx.hash;
      } catch (error) {
        console.error(error, "\n");
        process.exit(1);
      }
    }
  );
