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

  uint16 public constant FEE_PCT = 800;
  uint16 public constant PUBLISHER_PCT = 9200;
  uint16 public constant BASE_PCT = 10000;

  bool public paused;   
  bool public onlyWhiteList; 

  mapping(address => bool) public whitelisted; 
  mapping(address => uint256) public mintedBalance;  

  address publisher;

  event CostChanged(uint256 indexed _previousCost, uint256 indexed _newCost);
  event BaseURIChanged(string indexed _oldBaseURI, string indexed _newBaseURI);
  event BaseExtensionChanged(string indexed _oldBaseExtension, string indexed _newBaseExtension);
  event PausedChanged(bool indexed _oldPaused, bool indexed _newPaused);
  event OnlyWhiteListChanged(bool indexed _oldOnlyWhitelist, bool indexed _newOnlyWhitelist);
  event PublisherChanged(address indexed _oldPublisher, address indexed _newPublisher);

  constructor(  
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    uint256 _cost,
    uint256 _maxSupply,
    IERC20 _token,
    address _publisher,
    bool _paused,
    bool _onlyWhiteList
  ) ERC721(_name, _symbol) {
    cost = _cost;
    maxSupply = _maxSupply;
    setBaseURI(_initBaseURI);
    token = IERC20(_token);
    publisher = _publisher;
    paused = _paused;
    onlyWhiteList = _onlyWhiteList;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function _checkOwnerOrPublisher() internal view virtual {
    require(owner() == _msgSender() || publisher == _msgSender(), "Ownable: caller is not the owner or publisher");
  }

  modifier onlyOwnerOrPublisher() {
    _checkOwnerOrPublisher();
    _;
  }


  function mint(address _to, uint256 _mintAmount, uint256 transferAmount) public {   
    uint256 supply = totalSupply();
    require(!paused);    
    require(_mintAmount > 0);
    require(supply + _mintAmount <= maxSupply);

    if (msg.sender != owner() && msg.sender != publisher) {
        if(whitelisted[_to] == false) {
          require(onlyWhiteList==false, "only whitelist addresses can mint");
        }
        if (cost > 0){
          uint256 balanceBefore = token.balanceOf(address(this));
          require(
            token.transferFrom(_msgSender(), address(this), transferAmount),
            "Minting Fee Transfer Failed."
          );
          uint256 balanceAfter = token.balanceOf(address(this));
          require(balanceAfter - balanceBefore >= _mintAmount*cost, "Insufficient funds provided.");
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

  function setCost(uint256 _cost) public onlyOwnerOrPublisher {
    uint256 oldCost = cost;
    cost = _cost;
    emit CostChanged(oldCost, _cost);
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner { 
    string memory oldBaseURI = baseURI;
    baseURI = _newBaseURI;
    emit BaseURIChanged(oldBaseURI, _newBaseURI);
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    string memory oldBaseExtension = baseExtension; 
    baseExtension = _newBaseExtension;
    emit BaseExtensionChanged(oldBaseExtension, _newBaseExtension);
  }

  function pause(bool _state) public onlyOwner {  
    bool oldPaused = paused;
    paused = _state;
    emit PausedChanged(oldPaused, _state);
  }

  function setOnlyWhitelist(bool _state) public onlyOwner { 
    bool oldOnlyWhiteList = onlyWhiteList;
    onlyWhiteList = _state;
    emit OnlyWhiteListChanged(oldOnlyWhiteList, _state);
  }
 
 function whitelistUser(address _user) public onlyOwner { 
    whitelisted[_user] = true;
  }
 
  function removeWhitelistUser(address _user) public onlyOwner {  
    whitelisted[_user] = false;
  }

  function setPublisher(address _publisher) public onlyOwnerOrPublisher {
    require(_publisher != address(0), "New address can't be the 0 address.");
    address oldPublisher = publisher;
    publisher = _publisher;
    emit PublisherChanged(oldPublisher, _publisher);
  }

  function _transfer(address, address, uint256) internal virtual override {
    revert("This license is untransferable.");
  }

  function transferFrom(address, address, uint256) public virtual override(ERC721, IERC721) {
    revert("This license is untransferable.");
  }
  
  function safeTransferFrom(address, address, uint256, bytes memory) public virtual override(ERC721, IERC721) {
    revert("This license is untransferable.");
  }

  function safeTransferFrom(address, address, uint256) public virtual override(ERC721, IERC721) {
    revert("This license is untransferable.");
  }


  function withdraw() public onlyOwnerOrPublisher{ 
    uint amount = token.balanceOf(address(this));
    require(amount > 0, "balance is 0 in contract");
    require(token.transfer(owner(), amount*FEE_PCT/BASE_PCT));
    require(token.transfer(publisher, amount*PUBLISHER_PCT/BASE_PCT));
  }
}