module apps::Storage {
    use std::signer;
    use aptos_framework::account;
    use std::string::String;
    use std::string::utf8;

    const ERROR: u64 = 101;

    struct Storage<T: store> has key {
        val: T
    }

    public fun store<T: store>(account: &signer, val: T) {
        let addr = signer::address_of(account);
        assert!(!exists<Storage<T>>(addr), ERROR);
        let to_store = Storage { val };
        move_to(account, to_store);
    }

    public fun get<T: store>(account: &signer): T acquires Storage {
        let addr = signer::address_of(account);
        assert!(exists<Storage<T>>(addr), ERROR);
        let Storage { val } = move_from<Storage<T>>(addr);
        val
    }

    #[test(account = @0x123)]
    fun test_store_u128(account: signer) acquires Storage {
        let value: u128 = 100;
        store(&account, value);
        assert!(value == get<u128>(&account), ERROR)
    }

    #[test]
    fun test_store_diff_types() acquires Storage {
        let user1 = account::create_account_for_test(@0x1);
        let value1: u64 = 10;
        let value2: u128 = 20;
        let value3: String = utf8(b"hi");

        //user1 storing different types
        store(&user1, value1);
        // store(&user1,value1);//we can't store of same type twice
        store(&user1, value2);
        store(&user1, value3);

        assert!(value1 == get<u64>(&user1), ERROR);
        assert!(value2 == get<u128>(&user1), ERROR);
        assert!(value3 == get<String>(&user1), ERROR);

        //now the user2 storing differnt types
        let user2 = account::create_account_for_test(@0x2);

        // user2 storing different types
        store(&user2, value1);
        // store(&user1,value1);//we can't store of same type twice
        store(&user2, value2);
        store(&user2, value3);

        assert!(value1 == get<u64>(&user2), ERROR);
        assert!(value2 == get<u128>(&user2), ERROR);
        assert!(value3 == get<String>(&user2), ERROR);
    }
}
