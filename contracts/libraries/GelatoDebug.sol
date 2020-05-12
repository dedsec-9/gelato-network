pragma solidity ^0.6.6;

library GelatoDebug {
    function revertWithErrorString(bytes memory _bytes, string memory _tracingInfo)
        internal
        pure
    {
        // 68: 32-location, 32-length, 4-ErrorSelector, UTF-8 err
        if (_bytes.length % 32 == 4) {
            bytes4 selector;
            assembly { selector := mload(add(0x20, _bytes)) }
            if (selector == 0x08c379a0) {  // Function selector for Error(string)
                assembly { _bytes := add(_bytes, 68) }
                revert(string(abi.encodePacked(_tracingInfo, string(_bytes))));
            } else {
                revert(string(abi.encodePacked(_tracingInfo, "NoErrorSelector")));
            }
        } else {
            revert(string(abi.encodePacked(_tracingInfo, "UnexpectedReturndata")));
        }
    }
}