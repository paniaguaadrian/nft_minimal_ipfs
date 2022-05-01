// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
import '@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol';
import '@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol';

contract RandomIpfsNft is ERC721URIStorage, VRFConsumerBaseV2 {
    VRFCoordinatorV2Interface immutable i_vrfCoordinator;
    bytes32 public immutable i_gasLane;
    uint64 public immutable i_subscriptionId;
    uint32 public immutable i_callbackGasLimit;
    uint256 public s_tokenCounter;

    uint16 public constant REQUEST_CONFIRMATION = 3;
    uint32 public constant NUM_WORDS = 1;
    uint256 public constant MAX_CHANGE_VALUE = 100;

    mapping(uint256 => address) public s_requestIdToSender;

    string[3] public s_dogTokenUris;

    constructor(
        address vrfCoordinatorV2,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit,
        string[3] memory dogTokenUris
    ) ERC721('Random IPFS NFT', 'RIN') VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_tokenCounter = 0;
        s_dogTokenUris = dogTokenUris;
        // 0 => st.bernard
        // 1 => Pug
        // 2 => Shiba
    }

    // * Mint a random puppy (NFT)
    // Sending a request using Chainlink to get a random puppy/number
    function requestDoggie() public returns (uint256 requestId) {
        requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane, // price per gas
            i_subscriptionId,
            REQUEST_CONFIRMATION,
            i_callbackGasLimit, // max gas amount
            NUM_WORDS
        );
        s_requestIdToSender[requestId] = msg.sender;
    }

    // * Fullfull the random number => Mint the random Doggy
    // To mint the nft, we will call an openzeppelin contract (safeMint function)
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        // Owner of the dog (who call requestDoggy()
        address dogOwner = s_requestIdToSender[requestId];
        // To mint.. Asign this NFT a tokenId
        uint256 newTokenId = s_tokenCounter;
        s_tokenCounter = s_tokenCounter + 1;
        // Did we get a random dog?
        // is the st.bernard super random?
        uint256 moddedRng = randomWords[0] % MAX_CHANGE_VALUE;
        uint256 breed = getBreedFromModdedRng(moddedRng);
        _safeMint(dogOwner, newTokenId);
        // Set the token URI
        _setTokenURI(newTokenId, s_dogTokenUris[breed]);
    }

    function getChangeArray() public pure returns (uint256[3] memory) {
        // Random number between 0 and 9 = st.bernard
        // Random number between 10 and 29 = pug
        // Random number between 30 and 99 = shiba inu
        return [10, 30, MAX_CHANGE_VALUE];
    }

    function getBreedFromModdedRng(uint256 moddedRng)
        public
        pure
        returns (uint256)
    {
        uint256 cumulativeSum = 0;
        uint256[3] memory changeArray = getChangeArray();

        for (uint256 i = 0; i < changeArray.length; i++) {
            if (
                moddedRng >= cumulativeSum &&
                moddedRng < cumulativeSum + changeArray[i]
            ) {
                return i;
            }
            cumulativeSum = cumulativeSum + changeArray[i];
        }
    }
}
