module apps::Company {

    use std::vector;
    use std::signer;

    struct Employee has key, copy, drop, store {
        name: vector<u8>,
        age: u8,
        income: u64
    }

    struct Company has drop, key {
        people: vector<Employee>
    }

    public fun create_employee(
        caller: &signer, _employee: Employee, _company: &mut Company
    ): Employee {
        assert!(signer::address_of(caller) == @apps, 1);
        let newEmployee = Employee {
            name: _employee.name,
            age: _employee.age,
            income: _employee.income
        };
        add_employee(newEmployee, _company);
        move_to(caller, Company { people: vector[newEmployee] });
        return newEmployee

    }

    fun add_employee(newEmployee: Employee, _company: &mut Company) {
        vector::push_back(&mut _company.people, newEmployee);
    }

    public fun increase_income(caller: &signer, index: u8, bonus: u64) acquires Company {
        assert!(signer::address_of(caller) == @apps, 1);
        let company_curr_data = borrow_global_mut<Company>(signer::address_of(caller));
        let employee_curr_data = vector::borrow_mut(
            &mut company_curr_data.people, index as u64
        );
        employee_curr_data.income = employee_curr_data.income + bonus;

    }

    public fun decrease_income(caller: &signer, index: u8, amount: u64) acquires Company {
        assert!(signer::address_of(caller) == @apps, 1);
        let company_curr_data = borrow_global_mut<Company>(signer::address_of(caller));
        let employee_curr_data = vector::borrow_mut(
            &mut company_curr_data.people, index as u64
        );
        employee_curr_data.income = employee_curr_data.income - amount;

    }

    public fun multiple_income(caller: &signer, index: u8, bonus: u64) acquires Company {
        assert!(signer::address_of(caller) == @apps, 1);
        let company_curr_data = borrow_global_mut<Company>(signer::address_of(caller));
        let employee_curr_data = vector::borrow_mut(
            &mut company_curr_data.people, index as u64
        );
        employee_curr_data.income = employee_curr_data.income * bonus;

    }

    public fun divide_income(caller: &signer, index: u8, bonus: u64) acquires Company {
        assert!(signer::address_of(caller) == @apps, 1);
        let company_curr_data = borrow_global_mut<Company>(signer::address_of(caller));
        let employee_curr_data = vector::borrow_mut(
            &mut company_curr_data.people, index as u64
        );
        employee_curr_data.income = employee_curr_data.income / bonus;

    }

    #[test(admin = @apps)]
    fun test_create_employee(admin: &signer) {
        let employee = Employee { name: b"H", age: 11, income: 1000000 };

        //we need to pass Employees resource of H
        let employees = Company { people: (vector[employee]) };

        let createdEmployee = create_employee(admin, employee, &mut employees);
        assert!(createdEmployee.name == employee.name, 1);

    }

    #[test(admin = @apps)]
    fun test_all_flows(admin: &signer) acquires Company {
        let employee = Employee { name: b"Shark", age: 12, income: 200 };

        let employees = Company { people: (vector[employee]) };

        // increase income

        increase_income(admin, 0, 2);
        let company_data = borrow_global<Company>(signer::address_of(admin));
        let updatedEmployeeData = vector::borrow(&company_data.people, 0);
        assert!(202 == updatedEmployeeData.income, 1);

        // decrease income

        decrease_income(admin, 0, 2);
        let company_data = borrow_global<Company>(signer::address_of(admin));
        let updatedEmployeeData = vector::borrow(&company_data.people, 0);
        assert!(200 == updatedEmployeeData.income, 1);

        //multiple income

        multiple_income(admin, 0, 10);
        let company_data = borrow_global<Company>(signer::address_of(admin));
        let updatedEmployeeData = vector::borrow(&company_data.people, 0);
        assert!(2000 == updatedEmployeeData.income, 1);

        //divide income

        divide_income(admin, 0, 1);
        let company_data = borrow_global<Company>(signer::address_of(admin));
        let updatedEmployeeData = vector::borrow(&company_data.people, 0);
        assert!(2000 == updatedEmployeeData.income, 1);

    }
}
