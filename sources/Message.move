module apps::Message {
    use std::signer;
    use std::string::{Self, utf8};
    use aptos_framework::account;

    struct Message has key {
        my_message: string::String
    }

    public entry fun create_message(account: &signer, msg: string::String) acquires Message {
        let signer_addr = signer::address_of(account);
        if (exists<Message>(signer_addr)) {
            let old_message = &mut borrow_global_mut<Message>(signer_addr).my_message;
            *old_message = msg;
        } else {
            move_to<Message>(account, Message { my_message: msg });
        }
    }

    #[test(caller = @0x123)]
    public fun test_flow(caller: &signer) acquires Message {
        account::create_account_for_test(signer::address_of(caller));
        let msg = utf8(b"hi");
        create_message(caller, msg);

        let new_msg = utf8(b"new message");
        create_message(caller, new_msg);
        let stored_msg = borrow_global<Message>(signer::address_of(caller)).my_message;
        assert!(stored_msg == new_msg, 1);

    }
}
