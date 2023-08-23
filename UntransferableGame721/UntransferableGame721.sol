// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";


contract UntransferableGameLicense is ERC721Enumerable, Ownable {
  using Strings for uint256;
  IERC20 token;
  string public baseURI;  
  string public baseExtension = ".json";
  
  uint256 public cost; 
  uint256 public maxSupply;

  bool public paused = false;   
  bool public onlyWhiteList = false; 

  mapping(address => bool) public whitelisted; 
  mapping(address => uint256) public mintedBalance;  

  constructor(  
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    uint256 _cost,
    uint256 _maxSupply,
    IERC20 _token
  ) ERC721(_name, _symbol) {
    cost = _cost;
    maxSupply = _maxSupply;
    setBaseURI(_initBaseURI);
    token = IERC20(_token);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function mint(address _to, uint256 _mintAmount) public payable {   
    uint256 supply = totalSupply();
    require(!paused);    
    require(_mintAmount > 0);
    require(supply + _mintAmount <= maxSupply);

    if (msg.sender != owner()) {
        if(whitelisted[_to] == false) {
            require(onlyWhiteList==false, "only whitelist addresses can mint");
        }
        if (cost > 0){
          require(
            token.transferFrom(_msgSender(), address(this), cost * _mintAmount),
            "Minting Fee Transfer Failed."
          );
        }
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(_to, supply + i);
    }

    mintedBalance[_to] += _mintAmount;
  }

  function walletOfOwner(address _owner) public view returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, baseExtension)) : "";
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner { 
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner { 
    baseExtension = _newBaseExtension;
  }

  function pause(bool _state) public onlyOwner {  
    paused = _state;
  }

  function setOnlyWhitelist(bool _state) public onlyOwner { 
    onlyWhiteList = _state;
  }
 
 function whitelistUser(address _user) public onlyOwner { 
    whitelisted[_user] = true;
  }
 
  function removeWhitelistUser(address _user) public onlyOwner {  
    whitelisted[_user] = false;
  }

  function _transfer(address from, address to, uint256 tokenId) internal virtual override {
    revert("This license is untransferable.");
  }

  function transferFrom(address from, address to, uint256 tokenId) public virtual override(ERC721, IERC721) {
    revert("This license is untransferable.");
  }
  
  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override(ERC721, IERC721) {
    revert("This license is untransferable.");
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override(ERC721, IERC721) {
    revert("This license is untransferable.");
  }

  function withdraw(address _to) public onlyOwner{ 
    uint amount = token.balanceOf(address(this));
    require(amount > 0, "balance is 0 in contract");
    token.transfer(_to, amount);
  }
}
