// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

contract BlockgamesNFT is ERC721, ERC721Enumerable, Ownable {
    mapping(string => bool) private takenNames;
    mapping(uint256 => Attr) public attributes;

    struct Attr {
        string name;
        string material;
        uint8 speed;
        uint8 attack;
        uint8 defence; 
    }

    constructor() ERC721("Bgames", "BGAME") {}

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721) {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function mint(
        address to, 
        uint256 tokenId, 
        string memory _name, 
        string memory _material, 
        uint8 _speed, 
        uint8 _attack, 
        uint8 _defence) 
    public onlyOwner {
        _safeMint(to, tokenId);
        attributes[tokenId] = Attr(_name, _material, _speed, _attack, _defence);
    }

    function getSvg(uint tokenId) private view returns (string memory) {
        string memory svg;
        svg = svg = "<svg width='512px' height='512px' viewBox='0 0 512 512' xmlns='http://www.w3.org/2000/svg'><path fill='#000' d='M467.838 35.848c-53.208 3.518-101.284 8.091-139.14 50.18 9.869 29.563 26.168 65.884 46.613 95.234 20.504 29.436 44.758 50.59 68.61 53.297 35.265-33.057 53.699-112.599 23.917-198.711zM194.207 44.36c-.962.02-1.94.066-2.937.139-16.94 1.247-26.293 7.65-33.825 17.941-7.532 10.291-12.558 25.017-17.384 41.317-5.43 18.334-6.273 41.726-1.663 60.482 4.528 18.418 13.492 31.204 26.94 34.455.188-1.168.42-2.526.605-4.502.82-8.766 3.214-23.576 14.891-42.714-7.75-7.452-14.67-13.694-18.121-22.618-2.074-5.361-2.392-11.595-.84-17.992 1.552-6.396 4.726-13.139 9.615-21.26l.037-.06.037-.06c8.568-13.674 26.544-21.686 43.514-27.745 5.395-1.926 10.528-3.402 15.422-4.652-11.153-7.45-21.857-13.03-36.291-12.73zm45.07 27.002c-5.416 1.164-12.07 3.04-18.82 5.45-15.466 5.521-31.427 14.998-35.309 21.138-4.38 7.29-6.778 12.784-7.726 16.692-.952 3.925-.7 6.08.215 8.447 1.831 4.735 8.77 11.123 19.093 21.592l4.616 4.68-3.698 5.437c-5.348 7.864-8.79 14.564-11.072 20.351a70.936 54.43 66.039 0 0 17.928 6.88c2.391 57.506-19.43 43.882-70.535 73.605l15.888 31.69c26.64-10.285 42.457-16.219 56.041-28.891 11.993 12.066 26.85 22.39 44.155 33.437-.035 11.558-51.405 80.237-52.492 79.875a30.273 30.273 0 0 0 3.261 3.242c29.1 9.088 53.46 8.208 75.89 1.272.097-.294.2-.588.296-.881 12.757-4.462 25.877-10.432 38.629-17.43 20.587-12.745 40.445-29.295 61.107-45.845-10.31-22.79-41.559-34.836-62.133-43.946 9.77-20.016 5.393-41.39 2.516-60.55 18.737-1.992 33.016-7.841 46.527-15.145-.488-.689-.989-1.363-1.472-2.057-7.049-10.118-13.588-20.911-19.56-31.931-28.224 12.084-59.03 16.997-90.142.855a70.936 54.43 66.039 0 0-.117-66.955 70.936 54.43 66.039 0 0-13.086-21.012zM15.471 87.31l3.287 34.09 52.6 107.77 21.568-10.526-52.383-107.325-25.072-24.01zm97.066 139.566l-46.756 22.822 3.137 18.496 56.271-27.464-12.652-13.854zm2.318 36.701l-21.568 10.528 16.668 34.15 21.568-10.527-16.668-34.15zm255.858 73.934c-12.264 9.86-24.631 19.557-37.522 28.209 26.448 38.685 47.77 79.923 73.047 117.004l35.82-14.75c-26.576-46.832-44.463-82.605-71.345-130.463zm-100.254 56.808c-15.27 3.338-31.566 4.213-49.07 1.727-7.565 29.607-17.662 59.909-25.95 94.04l33.711 4.917c13.214-31.921 28.812-66.285 41.309-100.684z'/></svg>";        
        return svg;
    }    

    function tokenURI(uint256 tokenId) override(ERC721) public view returns (string memory) {
        string memory json = Base64.encode(
            bytes(string(
                abi.encodePacked(
                    '{"name": "', attributes[tokenId].name, '",',
                    '"image_data": "', getSvg(tokenId), '",',
                    '"attributes": [{"trait_type": "Speed", "value": ', uint2str(attributes[tokenId].speed), '},',
                    '{"trait_type": "Attack", "value": ', uint2str(attributes[tokenId].attack), '},',
                    '{"trait_type": "Defence", "value": ', uint2str(attributes[tokenId].defence), '},',
                    '{"trait_type": "Material", "value": "', attributes[tokenId].material, '"}',
                    ']}'
                )
            ))
        );
        return string(abi.encodePacked('data:application/json;base64,', json));
    }    
}
