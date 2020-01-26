import { internalTask } from "@nomiclabs/buidler/config";
import { utils } from "ethers";

export default internalTask(
  "gc-mint:defaultpayload:ActionKyberTradeKovan",
  `Returns a hardcoded actionPayloadWithSelector of ActionKyberTradeKovan`
)
  .addFlag("log")
  .setAction(async ({ log }) => {
    try {
      if (network.name != "kovan") throw new Error("wrong network!");

      const contractname = "ActionKyberTradeKovan";
      // action(_user, _userProxy, _src, _srcAmt, _dest, _minConversionRate)
      const functionname = "action";
      // Params
      const { luis: user } = await run("bre-config", {
        addressbookcategory: "EOA"
      });
      const { luis: userProxy } = await run("bre-config", {
        addressbookcategory: "userProxy"
      });
      const { DAI: src, KNC: dest } = await run("bre-config", {
        addressbookcategory: "erc20"
      });
      /*const { ETH: dest } = await run("bre-config", {
        addressbookcategory: "kyber"
      });*/
      const srcAmt = utils.parseUnits("100", 18);

      // Params as sorted array of inputs for abi.encoding
      // action(_user, _userProxy, _src, _srcAmt, _dest)
      const inputs = [user, userProxy, src, srcAmt, dest];
      // Encoding
      const payloadWithSelector = await run("abi-encode-withselector", {
        contractname,
        functionname,
        inputs,
        log
      });
      return payloadWithSelector;
    } catch (err) {
      console.error(err);
      process.exit(1);
    }
  });