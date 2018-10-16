pragma solidity ^0.4.24;

import './openzeppelin-solidity/contracts/math/SafeMath.sol';
import './openzeppelin-solidity/contracts/ownership/Ownable.sol';
import './openzeppelin-solidity/contracts/token/ERC20/BasicToken.sol';

/**
 * @title Withdrawable token
 * @dev Token that can be the withdrawal.
 */
contract WithdrawableToken is BasicToken, Ownable {
    using SafeMath for uint256;

    bool public withdrawingFinished = false;

    event Withdraw(address _from, address _to, uint256 _value);
    event WithdrawFinished();

    modifier canWithdraw() {
        require(!withdrawingFinished);
        _;
    }

    modifier hasWithdrawPermission() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Withdraw the amount of tokens to onwer.
     * @param _from address The address which owner want to withdraw tokens form.
     * @param _value uint256 the amount of tokens to be transferred.
     */
    function withdraw(address _from, uint256 _value) public
        hasWithdrawPermission
        canWithdraw
        returns (bool)
    {
        require(_value <= balances[_from]);

        balances[_from] = balances[_from].sub(_value);
        balances[owner] = balances[owner].add(_value);

        emit Transfer(_from, owner, _value);
        emit Withdraw(_from, owner, _value);

        return true;
    }

    /**
     * @dev Withdraw the amount of tokens to another.
     * @param _from address The address which owner want to withdraw tokens from.
     * @param _to address The address which owner want to transfer to.
     * @param _value uint256 the amount of tokens to be transferred.
     */
    function withdrawFrom(address _from, address _to, uint256 _value) public
        hasWithdrawPermission
        canWithdraw
        returns (bool)
    {
        require(_value <= balances[_from]);
        require(_to != address(0));

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);

        emit Transfer(_from, _to, _value);
        emit Withdraw(_from, _to, _value);

        return true;
    }

    /**
     * @dev Function to stop withdrawing new tokens.
     * @return True if the operation was successful.
     */
    function finishingWithdrawing() public
        onlyOwner
        canWithdraw
        returns (bool)
    {
        withdrawingFinished = true;

        emit WithdrawFinished();

        return true;
    }
}