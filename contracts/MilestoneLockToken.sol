pragma solidity ^0.4.24;

import './openzeppelin-solidity/contracts/math/SafeMath.sol';
import './openzeppelin-solidity/contracts/ownership/Ownable.sol';
import './openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol';

/**
 * @title Milestone Lock Token
 * @dev Token lock that can be the milestone policy applied.
 */
contract MilestoneLockToken is StandardToken, Ownable {
    using SafeMath for uint256;

    struct Policy {
        uint256 kickOff;
        uint256[] periods;
        uint8[] percentages;
    }

    struct MilestoneLock {
        uint8[] policies;
        uint256[] standardBalances;
    }

    uint8 constant MAX_POLICY = 100;
    uint256 constant MAX_PERCENTAGE = 100;

    mapping(uint8 => Policy) internal policies;
    mapping(address => MilestoneLock) internal milestoneLocks;

    event SetPolicyKickOff(uint8 policy, uint256 kickOff);
    event PolicyAdded(uint8 policy);
    event PolicyRemoved(uint8 policy);
    event PolicyAttributeAdded(uint8 policy, uint256 period, uint8 percentage);
    event PolicyAttributeRemoved(uint8 policy, uint256 period);
    event PolicyAttributeModified(uint8 policy, uint256 period, uint8 percentage);

    /**
     * @dev Transfer token for a specified address when enough available unlock balance.
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */
    function transfer(address _to, uint256 _value) public
        returns (bool)
    {
        require(getAvailableBalance(msg.sender) >= _value);

        return super.transfer(_to, _value);
    }

    /**
     * @dev Transfer tokens from one address to another when enough available unlock balance.
     * @param _from address The address which you want to send tokens from.
     * @param _to address The address which you want to transfer to.
     * @param _value uint256 the amount of tokens to be transferred.
     */
    function transferFrom(address _from, address _to, uint256 _value) public
        returns (bool)
    {
        require(getAvailableBalance(_from) >= _value);

        return super.transferFrom(_from, _to, _value);
    }

    /**
     * @dev Distribute the amounts of tokens to from owner's balance with the milestone policy to a policy-free user.
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     * @param _policy index of milestone policy to apply.
     */
    function distributeWithPolicy(address _to, uint256 _value, uint8 _policy) public
        onlyOwner
        returns (bool)
    {
        require(_to != address(0));
        require(_value <= balances[owner]);
        require(_policy < MAX_POLICY);
        require(_checkPolicyEnabled(_policy));

        balances[owner] = balances[owner].sub(_value);
        balances[_to] = balances[_to].add(_value);

        _setMilestoneTo(_to, _value, _policy);

        emit Transfer(owner, _to, _value);

        return true;
    }

    /**
     * @dev add milestone policy.
     * @param _policy index of the milestone policy you want to add.
     * @param _periods periods of the milestone you want to add.
     * @param _percentages unlock percentages of the milestone you want to add.
     */
    function addPolicy(uint8 _policy, uint256[] _periods, uint8[] _percentages) public
        onlyOwner
        returns (bool)
    {
        require(_policy < MAX_POLICY);
        require(!_checkPolicyEnabled(_policy));
        require(_periods.length > 0);
        require(_percentages.length > 0);
        require(_periods.length == _percentages.length);

        policies[_policy].periods = _periods;
        policies[_policy].percentages = _percentages;

        emit PolicyAdded(_policy);

        return true;
    }

    /**
     * @dev remove milestone policy.
     * @param _policy index of the milestone policy you want to remove.
     */
    function removePolicy(uint8 _policy) public
        onlyOwner
        returns (bool)
    {
        require(_policy < MAX_POLICY);

        delete policies[_policy];

        emit PolicyRemoved(_policy);

        return true;
    }

    /**
     * @dev get milestone policy information.
     * @param _policy index of milestone policy.
     */
    function getPolicy(uint8 _policy) public
        view
        returns (uint256 kickOff, uint256[] periods, uint8[] percentages)
    {
        require(_policy < MAX_POLICY);

        return (
            policies[_policy].kickOff,
            policies[_policy].periods,
            policies[_policy].percentages
        );
    }

    /**
     * @dev set milestone policy's kickoff time.
     * @param _policy index of milestone poicy.
     * @param _time kickoff time of policy.
     */
    function setKickOff(uint8 _policy, uint256 _time) public
        onlyOwner
        returns (bool)
    {
        require(_policy < MAX_POLICY);
        require(_checkPolicyEnabled(_policy));

        policies[_policy].kickOff = _time;

        return true;
    }

    /**
     * @dev add attribute to milestone policy.
     * @param _policy index of milestone policy.
     * @param _period period of policy attribute.
     * @param _percentage percentage of unlocking when reaching policy.
     */
    function addPolicyAttribute(uint8 _policy, uint256 _period, uint8 _percentage) public
        onlyOwner
        returns (bool)
    {
        require(_policy < MAX_POLICY);
        require(_checkPolicyEnabled(_policy));

        Policy storage policy = policies[_policy];

        for (uint256 i = 0; i < policy.periods.length; i++) {
            if (policy.periods[i] == _period) {
                revert();
                return false;
            }
        }

        policy.periods.push(_period);
        policy.percentages.push(_percentage);

        emit PolicyAttributeAdded(_policy, _period, _percentage);

        return true;
    }

    /**
     * @dev remove attribute from milestone policy.
     * @param _policy index of milestone policy attribute.
     * @param _period period of target policy.
     */
    function removePolicyAttribute(uint8 _policy, uint256 _period) public
        onlyOwner
        returns (bool)
    {
        require(_policy < MAX_POLICY);

        Policy storage policy = policies[_policy];
        
        for (uint256 i = 0; i < policy.periods.length; i++) {
            if (policy.periods[i] == _period) {
                _removeElementAt256(policy.periods, i);
                _removeElementAt8(policy.percentages, i);

                emit PolicyAttributeRemoved(_policy, _period);

                return true;
            }
        }

        revert();

        return false;
    }

    /**
     * @dev modify attribute from milestone policy.
     * @param _policy index of milestone policy.
     * @param _period period of target policy attribute.
     * @param _percentage percentage to modified.
     */
    function modifyPolicyAttribute(uint8 _policy, uint256 _period, uint8 _percentage) public
        onlyOwner
        returns (bool)
    {
        require(_policy < MAX_POLICY);

        Policy storage policy = policies[_policy];
        for (uint256 i = 0; i < policy.periods.length; i++) {
            if (policy.periods[i] == _period) {
                policy.percentages[i] = _percentage;

                emit PolicyAttributeModified(_policy, _period, _percentage);

                return true;
            }
        }

        revert();

        return false;
    }

    /**
     * @dev get policy's locked percentage of milestone policy from now.
     * @param _policy index of milestone policy for calculate locked percentage.
     */
    function getPolicyLockedPercentage(uint8 _policy) public view
        returns (uint256)
    {
        require(_policy < MAX_POLICY);

        Policy storage policy = policies[_policy];

        if (policy.periods.length == 0) {
            return 0;
        }
        
        if (policy.kickOff == 0 ||
            policy.kickOff > now) {
            return MAX_PERCENTAGE;
        }

        uint256 unlockedPercentage = 0;
        for (uint256 i = 0; i < policy.periods.length; i++) {
            if (policy.kickOff.add(policy.periods[i]) <= now) {
                unlockedPercentage =
                    unlockedPercentage.add(policy.percentages[i]);
            }
        }

        if (unlockedPercentage > MAX_PERCENTAGE) {
            return 0;
        }

        return MAX_PERCENTAGE.sub(unlockedPercentage);
    }

    /**
     * @dev change account's milestone policy.
     * @param _from address for milestone policy applyed from.
     * @param _prevPolicy index of original milestone policy.
     * @param _newPolicy index of milestone policy to be changed.
     */
    function modifyMilestoneFrom(address _from, uint8 _prevPolicy, uint8 _newPolicy) public
        onlyOwner
        returns (bool)
    {
        require(_from != address(0));
        require(_prevPolicy != _newPolicy);
        require(_prevPolicy < MAX_POLICY);
        require(_checkPolicyEnabled(_prevPolicy));
        require(_newPolicy < MAX_POLICY);
        require(_checkPolicyEnabled(_newPolicy));

        uint256 prevPolicyIndex = _getAppliedPolicyIndex(_from, _prevPolicy);
        require(prevPolicyIndex < MAX_POLICY);

        _setMilestoneTo(_from, milestoneLocks[_from].standardBalances[prevPolicyIndex], _newPolicy);

        milestoneLocks[_from].standardBalances[prevPolicyIndex] = 0;

        return true;
    }

    /**
     * @dev remove milestone policy from account.
     * @param _from address for applied milestone policy removes from.
     * @param _policy index of milestone policy remove. 
     */
    function removeMilestoneFrom(address _from, uint8 _policy) public
        onlyOwner
        returns (bool)
    {
        require(_from != address(0));
        require(_policy < MAX_POLICY);

        uint256 policyIndex = _getAppliedPolicyIndex(_from, _policy);
        require(policyIndex < MAX_POLICY);

        milestoneLocks[_from].standardBalances[policyIndex] = 0;

        return true;
    }

    /**
     * @dev get accounts milestone policy state information.
     * @param _account address for milestone policy applied.
     */
    function getUserMilestone(address _account) public
        view
        returns (uint8[] accountPolicies, uint256[] standardBalances)
    {
        return (
            milestoneLocks[_account].policies,
            milestoneLocks[_account].standardBalances
        );
    }

    /**
     * @dev available unlock balance.
     * @param _account address for available unlock balance.
     */
    function getAvailableBalance(address _account) public
        view
        returns (uint256)
    {
        return balances[_account].sub(getTotalLockedBalance(_account));
    }

    /**
     * @dev calcuate locked balance of milestone policy from now.
     * @param _account address for lock balance.
     * @param _policy index of applied milestone policy.
     */
    function getLockedBalance(address _account, uint8 _policy) public
        view
        returns (uint256)
    {
        require(_policy < MAX_POLICY);

        uint256 policyIndex = _getAppliedPolicyIndex(_account, _policy);
        if (policyIndex >= MAX_POLICY) {
            return 0;
        }

        MilestoneLock storage milestoneLock = milestoneLocks[_account];
        if (milestoneLock.standardBalances[policyIndex] == 0) {
            return 0;
        }

        uint256 lockedPercentage =
            getPolicyLockedPercentage(milestoneLock.policies[policyIndex]);
        return milestoneLock.standardBalances[policyIndex].div(MAX_PERCENTAGE).mul(lockedPercentage);
    }

    /**
     * @dev calcuate locked balance of milestone policy from now.
     * @param _account address for lock balance.
     */
    function getTotalLockedBalance(address _account) public
        view
        returns (uint256)
    {
        MilestoneLock storage milestoneLock = milestoneLocks[_account];

        uint256 totalLockedBalance = 0;
        for (uint256 i = 0; i < milestoneLock.policies.length; i++) {
            totalLockedBalance = totalLockedBalance.add(
                getLockedBalance(_account, milestoneLock.policies[i])
            );
        }

        return totalLockedBalance;
    }

    /**
     * @dev check for policy is enabled
     * @param _policy index of milestone policy.
     */
    function _checkPolicyEnabled(uint8 _policy) internal
        view
        returns (bool)
    {
        return (policies[_policy].periods.length > 0);
    }

    /**
     * @dev get milestone policy index applied to a user.
     * @param _to address The address which you want get to.
     * @param _policy index of milestone policy applied.
     */
    function _getAppliedPolicyIndex(address _to, uint8 _policy) internal
        view
        returns (uint8)
    {
        require(_policy < MAX_POLICY);

        MilestoneLock storage milestoneLock = milestoneLocks[_to];
        for (uint8 i = 0; i < milestoneLock.policies.length; i++) {
            if (milestoneLock.policies[i] == _policy) {
                return i;
            }
        }

        return MAX_POLICY;
    }

    /**
     * @dev set milestone policy applies to a user.
     * @param _to address The address which 
     * @param _value The amount to apply
     * @param _policy index of milestone policy to apply.
     */
    function _setMilestoneTo(address _to, uint256 _value, uint8 _policy) internal
    {
        uint8 policyIndex = _getAppliedPolicyIndex(_to, _policy);
        if (policyIndex < MAX_POLICY) {
            milestoneLocks[_to].standardBalances[policyIndex] = 
                milestoneLocks[_to].standardBalances[policyIndex].add(_value);
        } else {
            milestoneLocks[_to].policies.push(_policy);
            milestoneLocks[_to].standardBalances.push(_value);
        }
    }

    /**
     * @dev utility for uint256 array
     * @param _array target array
     * @param _index array index to remove
     */
    function _removeElementAt256(uint256[] storage _array, uint256 _index) internal
        returns (bool)
    {
        if (_array.length <= _index) {
            return false;
        }

        for (uint256 i = _index; i < _array.length - 1; i++) {
            _array[i] = _array[i + 1];
        }

        delete _array[_array.length - 1];
        _array.length--;

        return true;
    }

    /**
     * @dev utility for uint8 array
     * @param _array target array
     * @param _index array index to remove
     */
    function _removeElementAt8(uint8[] storage _array, uint256 _index) internal
        returns (bool)
    {
        if (_array.length <= _index) {
            return false;
        }

        for (uint256 i = _index; i < _array.length - 1; i++) {
            _array[i] = _array[i + 1];
        }

        delete _array[_array.length - 1];
        _array.length--;

        return true;
    }
}