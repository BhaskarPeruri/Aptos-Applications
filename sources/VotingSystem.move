module apps::VotingSystem {
    use std::signer;
    use std::vector;
    use std::simple_map::{Self, SimpleMap};
    use aptos_framework::account;

    const E_NOT_ADMIN: u64 = 1;
    const E_INITIALIZED: u64 = 2;
    const E_WINNER_ALREADY_DECLARED: u64 = 3;
    const E_DUPLICATE_CANDIDATE: u64 = 4;
    const E_ALREADY_VOTED: u64 = 5;
    const E_NOT_INITIALIZED: u64 = 6;

    struct CandidateList has key {
        //mapping address to no of votes
        //for ex: candidate1 => 100 votes
        //        candidate2 => 200 votes
        candidate_list: SimpleMap<address, u64>,
        c_list: vector<address>, //vector of candidate addresses
        winner: address
    }

    struct VotingList has key {
        voters: SimpleMap<address, u64>
    }

    public fun check_caller(addr: address) {
        assert!(addr == @apps, E_NOT_ADMIN);
    }

    public fun check_initialization(addr: address) {
        assert!(exists<CandidateList>(addr), 6);
        assert!(exists<VotingList>(addr), 6);
    }

    public fun check_UnInitialization(addr: address) {
        assert!(!exists<CandidateList>(addr), 2);
        assert!(!exists<VotingList>(addr), 2);
    }

    public fun check_unique_candidate(
        map: &SimpleMap<address, u64>, candidate_addr: &address
    ) {
        assert!(!simple_map::contains_key(map, candidate_addr), 4);

    }

    public fun check_candidate_exists(
        map: &SimpleMap<address, u64>, candidate_addr: &address
    ) {
        assert!(simple_map::contains_key(map, candidate_addr));

    }

    public fun initialize(admin: &signer) {
        let signer_addr = signer::address_of(admin);
        check_caller(signer_addr);
        //initialize only once
        check_UnInitialization(signer_addr);

        let c_store = CandidateList {
            candidate_list: simple_map::create(),
            c_list: vector::empty<address>(),
            winner: @0x0
        };

        let v_store = VotingList { voters: simple_map::create() };

        move_to(admin, c_store);
        move_to(admin, v_store);
    }

    public entry fun add_candidate(
        admin: &signer, candidate_addr: address
    ) acquires CandidateList {
        let signer_addr = signer::address_of(admin);
        check_caller(signer_addr);
        check_initialization(signer_addr);

        //candidate should not be added when the owner is declared
        let c_store = borrow_global_mut<CandidateList>(signer_addr);
        assert!(c_store.winner == @0x0, 3);
        //only unique candidates only
        check_unique_candidate(&c_store.candidate_list, &candidate_addr);

        //adding candidate to candidateList
        simple_map::add(&mut c_store.candidate_list, candidate_addr, 0);
        //storing the candidate address in vector
        vector::push_back(&mut c_store.c_list, candidate_addr);
    }

    public entry fun vote(
        caller: &signer, candidate_addr: address, store_addr: address
    ) acquires CandidateList, VotingList {
        let voter = signer::address_of(caller);
        check_initialization(store_addr);

        let c_store = borrow_global_mut<CandidateList>(store_addr);
        let v_store = borrow_global_mut<VotingList>(store_addr);

        //voting should be avoided when the winner is declared
        assert!(c_store.winner == @0x0, 3);
        //voter should be unique
        assert!(!simple_map::contains_key(&v_store.voters, &voter), 5);
        //only the registered candidates can get voting
        check_candidate_exists(&c_store.candidate_list, &candidate_addr);
        //add the votes to the corresponding candidate
        let votes = simple_map::borrow_mut(&mut c_store.candidate_list, &candidate_addr);
        *votes = *votes + 1;
        //add the voter to the VotingList voters mapping
        simple_map::add(&mut v_store.voters, voter, 1);

    }

    public entry fun declare_winner(acc: &signer) acquires CandidateList {
        let caller = signer::address_of(acc);
        check_caller(caller);

        let c_store = borrow_global_mut<CandidateList>(caller);
        //the winner should not be declared
        assert!(c_store.winner == @0x0, 3);

        let candidates = vector::length(&c_store.c_list);

        let i = 0;
        let max_votes = 0;
        let winner = @0x0;

        while (i < candidates) {
            let candidate = *vector::borrow(&c_store.c_list, (i as u64));
            let votes = simple_map::borrow(&c_store.candidate_list, &candidate);

            if (max_votes < *votes) {
                max_votes = *votes;
                winner = candidate;
            };

            i = i + 1;
        };

        c_store.winner = winner;
    }

    #[test(admin = @apps)]
    public entry fun test_flow(admin: &signer) acquires CandidateList, VotingList {
        let signer_addr = signer::address_of(admin);
        let c_addr1 = @0x1;
        let c_addr2 = @0x2;
        let voter1 = account::create_account_for_test(@0x3);
        let voter2 = account::create_account_for_test(@0x4);
        let voter3 = account::create_account_for_test(@0x5);
        let voter1_addr = signer::address_of(&voter1);
        let voter2_addr = signer::address_of(&voter2);
        let voter3_addr = signer::address_of(&voter3);

        initialize(admin);

        add_candidate(admin, c_addr1);
        add_candidate(admin, c_addr2);

        let candidateList = borrow_global<CandidateList>(signer_addr).candidate_list;
        assert!(simple_map::contains_key(&candidateList, &c_addr1));
        assert!(simple_map::contains_key(&candidateList, &c_addr2));

        vote(&voter1, c_addr1, signer_addr);
        vote(&voter2, c_addr1, signer_addr);
        vote(&voter3, c_addr2, signer_addr);

        let voters = borrow_global<VotingList>(signer_addr).voters;
        assert!(simple_map::contains_key(&voters, &voter1_addr));
        assert!(simple_map::contains_key(&voters, &voter2_addr));
        assert!(simple_map::contains_key(&voters, &voter3_addr));

        declare_winner(admin);
        let winner = borrow_global<CandidateList>(signer_addr).winner;
        assert!(winner == c_addr1, 0);

    }

    #[test]
    #[expected_failure(abort_code = E_NOT_ADMIN)]

    public entry fun test_initialize_not_Owner() {
        let not_owner = account::create_account_for_test(@0x2);
        initialize(&not_owner);
    }

    #[test(admin = @apps)]
    #[expected_failure(abort_code = E_INITIALIZED)]
    public entry fun test_initialize(admin: signer) {
        initialize(&admin);
        initialize(&admin);
    }

    #[test(admin = @apps)]
    #[expected_failure(abort_code = E_ALREADY_VOTED)]
    public entry fun test_vote_twice(admin: signer) acquires CandidateList, VotingList {
        let store_addr = signer::address_of(&admin);
        let voter1 = account::create_account_for_test(@0x1);
        let candidate1 = account::create_account_for_test(@0x2); //this is the signer
        let candidate1_addr = signer::address_of(&candidate1);

        initialize(&admin);
        add_candidate(&admin, candidate1_addr);

        vote(&voter1, candidate1_addr, store_addr);
        vote(&voter1, candidate1_addr, store_addr);

    }

    #[test(admin = @apps)]
    #[expected_failure(abort_code = E_NOT_INITIALIZED)]
    public entry fun test_Error_Inititalized(admin: signer) acquires CandidateList, VotingList {
        let store_addr = signer::address_of(&admin);
        let voter = account::create_account_for_test(@0x1);
        let candidate_addr = @0x2;
        vote(&voter, candidate_addr, store_addr);
    }

    #[test(admin = @apps)]
    #[expected_failure(abort_code = E_WINNER_ALREADY_DECLARED)]
    public entry fun test_add_candidate_after_winner_declared(
        admin: &signer
    ) acquires CandidateList, VotingList {
        let store_addr = signer::address_of(admin);
        let voter1 = account::create_account_for_test(@0x1);
        let voter2 = account::create_account_for_test(@0x2);
        let candidate1 = @0x3;
        let candidate2 = @0x4;

        initialize(admin);
        add_candidate(admin, candidate1);
        add_candidate(admin, candidate2);

        vote(&voter1, candidate1, store_addr);
        vote(&voter2, candidate1, store_addr);

        declare_winner(admin);
        add_candidate(admin, candidate1);
    }
}
