pragma solidity 0.7.0;

import "./IERC20.sol";
import "./IMintableToken.sol";
import "./IDividends.sol";
import "./SafeMath.sol";

contract Token is IERC20, IMintableToken, IDividends {
  // ------------------------------------------ //
  // ----- BEGIN: DO NOT EDIT THIS SECTION ---- //
  // ------------------------------------------ //
  using SafeMath for uint256;
  uint256 public totalSupply;
  uint256 public decimals = 18;
  string public name = "Test token";
  string public symbol = "TEST";
  mapping (address => uint256) public balanceOf;
  // ------------------------------------------ //
  // ----- END: DO NOT EDIT THIS SECTION ------ //  
  // ------------------------------------------ //

  mapping (address => mapping (address => uint256)) internal allowed;
  address[] public holderList; 
  uint256 index =0;
  mapping (address=> bool) public holderOrNot;
  mapping (address=> uint256) public holderListPosition; //Not use ATM but it might be useful to optimise the program in the future
  mapping (address=> uint256) public dividend; //instead of that we can also use a struct


  // IERC20

  function allowance(address owner, address spender) external view override returns (uint256) {
    return allowed[owner][spender];
    //revert();
  }

  function transfer(address to, uint256 value) external override returns (bool) {
    require(to != address(0));
    require(value <= balanceOf[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balanceOf[msg.sender] = balanceOf[msg.sender].sub(value);
    balanceOf[to] = balanceOf[to].add(value);
    //added to manage the distribution of dividend
      if (holderOrNot[to]==false){
        holderList.push(to);
        holderOrNot[to]=true;
        holderListPosition[to]=index;
        dividend[to]=0;
        index++;
      }
    emit Transfer(msg.sender, to, value);
    return true;
    //revert();
  }

  function approve(address spender, uint256 value) external override returns (bool) {
    allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
    //revert();
  }

  function transferFrom(address from, address to, uint256 value) external override returns (bool) {
    require(to != address(0));
    require(value <= balanceOf[from]);
    require(value <= allowed[from][msg.sender]);

    balanceOf[from] = balanceOf[from].sub(value);
    balanceOf[to] = balanceOf[to].add(value);
    allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
    //added to manage the distribution of dividend
    if (holderOrNot[to]==false){
        holderList.push(to);
        holderOrNot[to]=true;
        holderListPosition[to]=index;
        dividend[to]=0;
        index++;
      }
    emit Transfer(from, to, value);
    return true;
    //revert();
  }

  // IMintableToken

  function mint() external payable override { //to check amount
      //require(msg.sender != address(0), "ERC20: mint to the zero address");
      require(msg.value!=0);
      totalSupply =totalSupply.add(msg.value);
      balanceOf[msg.sender] = balanceOf[msg.sender].add(msg.value);
      //added to manage the distribution of dividend
      if (holderOrNot[msg.sender]==false){
        holderList.push(msg.sender);
        holderOrNot[msg.sender]=true;
        holderListPosition[msg.sender]=index;
        dividend[msg.sender]=0;
        index++;
      }
      emit Transfer(address(0), msg.sender, msg.value);
    //revert();
  }
    

  function burn(address payable dest) external override {
      //address(this).send(msg.sender,value);
      require(dest==payable(msg.sender));  //to verify par rapport à la fonction payable
      uint256 value = balanceOf[msg.sender];
      balanceOf[msg.sender]=balanceOf[msg.sender].sub(value); //similar to say =0
      totalSupply=totalSupply.sub(value);
      dest.transfer(value); //by default it's sent from the smart-contract reserve
      emit Transfer(msg.sender, address(0x0), value);
    //revert();
  }

  // IDividends
  function recordDividend() external payable override { 
      require(msg.value!=0);
      for (uint256 i = 0; i <holderList.length; i++){
        dividend[holderList[i]]+=msg.value.mul(balanceOf[holderList[i]].div(totalSupply));
      }
    //revert();
  }

  function getWithdrawableDividend(address payee) external view override returns (uint256) {
      return dividend[payee];
    //revert();
  }

  function withdrawDividend(address payable dest) external override {
      require(dest==payable(msg.sender));
      dest.transfer(dividend[msg.sender]);
      dividend[msg.sender]=0;
          //revert();
  }
}