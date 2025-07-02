module apps::FootBallStar {

    use std::signer;
    use aptos_framework::account;

    const E_STAR_ALREADY_EXISTS:u64 = 100;
    const E_STAR_NOT_EXISTS:u64 = 101;

    struct FootBallStar has key {
        name: vector<u8>,
        country: vector<u8>,
        position: u8,
        value: u64
    }

    public fun newStar(
        _name: vector<u8>, _country: vector<u8>, _position: u8
    ): FootBallStar {
        let footballstar =
            FootBallStar { name: _name, country: _country, position: _position, value: 0 };
        footballstar
    }

    public fun mint(to: &signer, star: FootBallStar) {
        let caller = signer::address_of(to);
        assert!(!exists<FootBallStar>(caller),E_STAR_ALREADY_EXISTS);
        move_to(to, star);
    }

    public fun get(owner: &signer): (vector<u8>, u64) acquires FootBallStar {
        assert!(
            exists<FootBallStar>(signer::address_of(owner)),
            E_STAR_NOT_EXISTS
        );

        let footballstar = borrow_global<FootBallStar>(signer::address_of(owner));
        return (footballstar.name, footballstar.value)

    }

    public fun card_exists(owner: &signer):bool   {
       
          return  exists<FootBallStar>(signer::address_of(owner))
        
        

    }

    public fun setPrice(owner: &signer, price: u64) acquires FootBallStar {
        assert!(
            exists<FootBallStar>(signer::address_of(owner)),
            E_STAR_NOT_EXISTS
        );
        let footballstar = borrow_global_mut<FootBallStar>(signer::address_of(owner));
        footballstar.value = price;

    }

    public fun transfer(owner: &signer, to: &signer) acquires FootBallStar {
        let owner = signer::address_of(owner);
        assert!(
            exists<FootBallStar>(owner),
            E_STAR_NOT_EXISTS
        );
        let taken_star = move_from<FootBallStar>(owner);
        move_to(to, taken_star);
    }

    #[test]
    fun test_flow_football() acquires FootBallStar{
        let footballstar = newStar(b"Ronaldo" ,b"Portugal", 7);
        let acc1 = account::create_account_for_test(@0x1);
        mint(&acc1, footballstar);

        let (name, value) = get(&acc1);
        assert!(name == b"Ronaldo", 1);
        assert!(value == 0, 2);

        assert!(card_exists(&acc1), 3);
        setPrice(&acc1, 100);


        let (name, value) = get(&acc1);
        assert!(value == 100, 4);

        let acc2 = account::create_account_for_test(@0x2);

        transfer(&acc1, &acc2);

        assert!(card_exists(&acc2), 5);






        
    }
}
