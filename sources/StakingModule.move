module apps::BasicTokens {

    use std::signer;
    friend apps::Staking;

    const E_NOT_AN_ADMIN: u64 = 1;
    const E_INSUFFICIENT_BALANCE: u64 = 2;

    struct Coin has store, drop {
        value: u64
    }

    struct Balance has key {
        coin: Coin
    }

    public(friend) fun createCoin(v: u64): Coin {
        let coin = Coin { value: v };
        coin
    }

    public fun publish_balance(admin: &signer, to: &signer) {
        let admin = signer::address_of(admin);
        assert!(admin == @apps, 1);
        let empty_coin = Coin { value: 0 };
        assert!(!exists<Balance>(signer::address_of(to)));
        move_to(to, Balance { coin: empty_coin });
    }

    public fun mint<CoinType: drop>(
        admin: &signer, mint_addr: address, amount: u64
    ) acquires Balance {
        let admin = signer::address_of(admin);
        assert!(admin == @apps, 1);
        deposit(mint_addr, Coin { value: amount });
    }

    public fun burn(admin: &signer, burn_addr: address, amount: u64) acquires Balance {
        let admin = signer::address_of(admin);
        assert!(admin == @apps, 1);
        let Coin { value: _ } = withdraw(burn_addr, amount);
    }

    public fun balance_of(addr: address): u64 acquires Balance {
        borrow_global<Balance>(addr).coin.value
    }

    public(friend) fun deposit(addr: address, check: Coin) acquires Balance {
        let balance = balance_of(addr);
        let balance_ref = &mut borrow_global_mut<Balance>(addr).coin.value;
        let Coin { value } = check;
        *balance_ref = balance + value;
    }

    public(friend) fun withdraw(addr: address, amount: u64): Coin acquires Balance {
        let balance = balance_of(addr);
        assert!(balance >= amount, E_INSUFFICIENT_BALANCE);
        let balance_ref = &mut borrow_global_mut<Balance>(addr).coin.value;
        *balance_ref = balance - amount;
        Coin { value: amount }
    }

    public fun transfer(from: &signer, to: address, amount: u64) acquires Balance {
        let from_addr = signer::address_of(from);
        assert!(from_addr != to, 2);
        let check = withdraw(from_addr, amount);
        deposit(to, check);
    }
}

module apps::Staking {
    use std::signer;
    use aptos_framework::account;
    use apps::BasicTokens;

    const E_INSUFFICIENT_BALANCE: u64 = 1;
    const E_ALREADY_STAKED: u64 = 2;
    const E_STAKERS_ONLY: u64 = 3;
    const E_INVALID_UNSTAKE_AMOUNT: u64 = 4;
    const DEFAULT_APY: u64 = 5;

    struct StakedBalance has key, drop {
        staked_balance: u64

    }

    public fun stake(acc: &signer, amount: u64) {
        let caller = signer::address_of(acc);
        let balance = BasicTokens::balance_of(caller);
        assert!(balance >= amount, E_INSUFFICIENT_BALANCE);
        assert!(!exists<StakedBalance>(caller), E_ALREADY_STAKED);
        BasicTokens::withdraw(caller, amount);
        move_to(acc, StakedBalance { staked_balance: amount });

    }

    public fun unstake(acc: &signer, amount: u64) acquires StakedBalance {
        let caller = signer::address_of(acc);
        assert!(exists<StakedBalance>(caller), E_STAKERS_ONLY);
        let staked_balance = borrow_global_mut<StakedBalance>(caller);
        let staked_amount = staked_balance.staked_balance;
        assert!(staked_amount >= amount, E_INVALID_UNSTAKE_AMOUNT);
        let coins = BasicTokens::createCoin(staked_amount);
        BasicTokens::deposit(caller, coins);
        staked_balance.staked_balance = staked_balance.staked_balance - amount;
        if (staked_balance.staked_balance == 0) {
            move_from<StakedBalance>(caller);
        }
    }

    public fun claim_rewards(acc: &signer) acquires StakedBalance {
        let caller = signer::address_of(acc);
        assert!(exists<StakedBalance>(caller), E_STAKERS_ONLY);
        let staked_balance = borrow_global_mut<StakedBalance>(caller);
        let staked_amount = staked_balance.staked_balance;
        assert!(staked_amount > 0, E_INSUFFICIENT_BALANCE);
        let apy = DEFAULT_APY;
        let reward_amount = (staked_amount * apy) / (10000);
        let coins = BasicTokens::createCoin(reward_amount);
        BasicTokens::deposit(caller, coins);
    }

    #[test(admin = @apps)]
    public fun test_flow_staking(admin: &signer) acquires StakedBalance {
        let user1 = account::create_account_for_test(@0x1);
        let user2 = account::create_account_for_test(@0x2);
        let user1_addr = signer::address_of(&user1);
        let user2_addr = signer::address_of(&user2);

        BasicTokens::publish_balance(admin, &user1);
        BasicTokens::publish_balance(admin, &user2);

        BasicTokens::mint<BasicTokens::Coin>(admin, user1_addr, 1000);
        BasicTokens::mint<BasicTokens::Coin>(admin, user2_addr, 1000);

        stake(&user1, 500);
        stake(&user2, 1000);

        let user1_staked_balance =
            borrow_global<StakedBalance>(user1_addr).staked_balance;
        assert!(user1_staked_balance == 500);

        let user2_staked_balance =
            borrow_global<StakedBalance>(user2_addr).staked_balance;
        assert!(user2_staked_balance == 1000);

        unstake(&user1, 200);
        unstake(&user2, 500);

        let user1_staked_balance =
            borrow_global<StakedBalance>(user1_addr).staked_balance;
        assert!(user1_staked_balance == 300);

        let user2_staked_balance =
            borrow_global<StakedBalance>(user2_addr).staked_balance;
        assert!(user2_staked_balance == 500);

        claim_rewards(&user1);
        let user1_staked_balance =
            borrow_global<StakedBalance>(user1_addr).staked_balance;
        assert!(user1_staked_balance == 300);

    }
}
