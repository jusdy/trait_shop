// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interface/ApesTraitsInterface.sol";

contract TraitShop is Ownable, ReentrancyGuard {
    mapping(address => uint256) private _ethBalances;
    address[] public whiteListedTokens;
    mapping(address => mapping(address => uint256)) private _tokenBalances;

    ApesTraitsInterface public apesTraits;
    address public secret;

    event TraitBought(
        address indexed buyer,
        uint256 indexed traitId,
        uint256 price,
        uint256 quantity,
        bool buyOnChain
    );

    constructor(
        address _apesTraits
    ) {
        apesTraits = ApesTraitsInterface(_apesTraits);
        // secret = _secret;
    }

    function setWhiteListedTokensAddress(
        address[] memory tokenAddress
    ) public onlyOwner {
        for (uint i = 0; i < tokenAddress.length; i++) {
            whiteListedTokens.push(tokenAddress[i]);
        }
    }

    function isTokenWhitelisted(
        address tokenAddress
    ) internal view returns (bool) {
        for (uint i = 0; i < whiteListedTokens.length; i++) {
            if (whiteListedTokens[i] == tokenAddress) {
                return true;
            }
        }
        return false;
    }

    modifier onlyWhitelistedToken(address tokenAddress) {
        require(
            isTokenWhitelisted(tokenAddress),
            "TraitShop: Token address is not whitelisted."
        );
        _;
    }

    function buyTraitWithETH(
        uint256 traitId,
        address sponsorAddress,
        uint256 quantity,
        uint256 price,
        uint commissionPercentage,
        bool buyOnChain
        // bytes memory signature
    ) external payable nonReentrant {
        // require(
        //     _verifyHashSignature(
        //         keccak256(
        //             abi.encode(
        //                 traitId,
        //                 sponsorAddress,
        //                 commissionPercentage,
        //                 quantity,
        //                 price,
        //                 buyOnChain,
        //                 msg.sender
        //             )
        //         ),
        //         signature
        //     ),
        //     "TraitShop: Signature is invalid"
        // );
        require(msg.value >= price, "TraitShop: Invalid price");

        uint256 commission = (msg.value * commissionPercentage) / 100;

        _ethBalances[owner()] += msg.value - commission;

        _ethBalances[sponsorAddress] += commission;

        if (buyOnChain) {
            apesTraits.mint(msg.sender, traitId, quantity);
        }

        emit TraitBought(msg.sender, traitId, msg.value, quantity, buyOnChain);
    }

    function buyTraitWithERC20(
        uint256 traitId,
        address sponsorAddress,
        uint256 quantity,
        uint256 price,
        address erc20TokenAddress,
        uint commissionPercentage,
        bool buyOnChain
        // bytes memory signature
    ) external onlyWhitelistedToken(erc20TokenAddress) nonReentrant {
        // require(
        //     _verifyHashSignature(
        //         keccak256(
        //             abi.encode(
        //                 traitId,
        //                 sponsorAddress,
        //                 commissionPercentage,
        //                 quantity,
        //                 price,
        //                 erc20TokenAddress,
        //                 buyOnChain,
        //                 msg.sender
        //             )
        //         ),
        //         signature
        //     ),
        //     "TraitShop: Signature is invalid"
        // );
        IERC20(erc20TokenAddress).transferFrom(
            msg.sender,
            address(this),
            price
        );

        uint256 commission = (price * commissionPercentage) / 100;

        _tokenBalances[owner()][erc20TokenAddress] += price - commission;

        _tokenBalances[sponsorAddress][erc20TokenAddress] += commission;

        if (buyOnChain) {
            apesTraits.mint(msg.sender, traitId, quantity);
        }

        emit TraitBought(msg.sender, traitId, price, quantity, buyOnChain);
    }

    function withdrawAll() external {
        uint256 ethBalance = _ethBalances[msg.sender];

        if (ethBalance > 0) {
            _ethBalances[msg.sender] = 0;
            payable(msg.sender).transfer(ethBalance);
        }

        address[] memory tokens = whiteListedTokens;
        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            uint256 tokenBalance = _tokenBalances[msg.sender][token];
            if (tokenBalance > 0) {
                _tokenBalances[msg.sender][token] = 0;
                IERC20(token).transfer(msg.sender, tokenBalance);
            }
        }
    }

    function getEthBalance(address account) external view returns (uint256) {
        return _ethBalances[account];
    }

    function getTokenBalance(
        address account,
        address token
    ) external view returns (uint256) {
        return _tokenBalances[account][token];
    }

    function setSecret(address _secret) external onlyOwner {
        secret = _secret;
    }

    function _verifyHashSignature(
        bytes32 freshHash,
        bytes memory signature
    ) internal view returns (bool) {
        bytes32 hash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", freshHash)
        );

        bytes32 r;
        bytes32 s;
        uint8 v;

        if (signature.length != 65) {
            return false;
        }
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        if (v < 27) {
            v += 27;
        }

        address signer = address(0);
        if (v == 27 || v == 28) {
            // solium-disable-next-line arg-overflow
            signer = ecrecover(hash, v, r, s);
        }
        return secret == signer;
    }
}