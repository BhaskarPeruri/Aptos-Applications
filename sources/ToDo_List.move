module apps::ToDo_List {
    use std::string::String;
    use aptos_std::table::{Self, Table};
    use std::signer;
    use aptos_framework::account;
    use aptos_framework::event;

    //Errors
    const E_NOT_INITIALIZED: u64 = 1;
    const ETASK_DOESNT_EXIST: u64 = 2;
    const ETASK_IS_COMPLETED: u64 = 3;

    struct Task has key, drop, store, copy {
        task_id: u64,
        addr: address,
        content: String,
        completed: bool
    }

    struct TodoList has key {
        tasks: Table<u64, Task>,
        task_counter: u64,
        set_task_event: event::EventHandle<Task>
    }

    public entry fun create_list(account: &signer) {
        //Initializing the struct
        let todoList = TodoList {
            tasks: table::new(),
            task_counter: 0,
            set_task_event: account::new_event_handle<Task>(account)
        };

        move_to(account, todoList);
    }

    public entry fun create_task(account: &signer, content: String) acquires TodoList {
        let signer_addr = signer::address_of(account);
        assert!(exists<TodoList>(signer_addr), E_NOT_INITIALIZED);
        //creating a new task with unique task_id
        let todoList = borrow_global_mut<TodoList>(signer_addr);

        let counter = todoList.task_counter + 1;

        let new_task = Task {
            task_id: counter,
            addr: signer_addr,
            content,
            completed: false
        };

        //adding the new task into the task table
        table::upsert(&mut todoList.tasks, counter, new_task);

        todoList.task_counter = counter;

        event::emit_event<Task>(
            &mut borrow_global_mut<TodoList>(signer_addr).set_task_event,
            new_task
        );

    }

    public entry fun complete_task(account: &signer, task_id: u64) acquires TodoList {
        let signer_addr = signer::address_of(account);
        assert!(exists<TodoList>(signer_addr), E_NOT_INITIALIZED);

        let todoList = borrow_global_mut<TodoList>(signer_addr);
        assert!(table::contains(&mut todoList.tasks, task_id), ETASK_DOESNT_EXIST);

        let status = table::borrow_mut(&mut todoList.tasks, task_id);
        assert!(status.completed == false, ETASK_IS_COMPLETED);
        status.completed = true;

    }

    #[test_only]
    use std::string;
    #[test(admin = @0x123)]
    public fun test_flow(admin: signer) acquires TodoList {
        account::create_account_for_test(signer::address_of(&admin));
        //creating list
        create_list(&admin);

        create_task(&admin, string::utf8(b"Hi"));

        let todoList = borrow_global<TodoList>(signer::address_of(&admin));
        assert!(todoList.task_counter == 1, 4);

        let task_count =
            event::counter(
                &borrow_global<TodoList>(signer::address_of(&admin)).set_task_event
            );
        assert!(task_count == 1, 5);

        let task_data = table::borrow(&todoList.tasks, todoList.task_counter);
        assert!(task_data.task_id == 1, 6);
        assert!(task_data.completed == false, 7);
        assert!(task_data.content == string::utf8(b"Hi"), 7);
        assert!(task_data.addr == signer::address_of(&admin), 8);

        //update tasks as completed
        complete_task(&admin, 1);
        let todoList = borrow_global_mut<TodoList>(signer::address_of(&admin));

        let task_record = table::borrow(&todoList.tasks, 1);
        assert!(task_record.task_id == 1, 10);
        assert!(task_record.completed == true, 11);
        assert!(task_record.content == string::utf8(b"Hi"), 12);
        assert!(task_record.addr == signer::address_of(&admin), 13);

    }

    #[test(admin = @0x123)]
    #[expected_failure(abort_code = E_NOT_INITIALIZED)]
    public entry fun test_account_cannot_update_task(admin: signer) acquires TodoList {
        account::create_account_for_test(signer::address_of(&admin));
        complete_task(&admin, 2);
    }
}
