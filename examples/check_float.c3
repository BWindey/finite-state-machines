module check_float;
import automaton;
import std::io;

fn Automaton create_float_checker(Allocator allocator) {
	Automaton float_checker;
	float_checker.init(
		allocator,
		state_count: 8, start_state: 0,
		alphabet: "+-.0123456789Ee", accepted_states: { 2, 4, 7 }
	);

	float_checker.add_transitions({
		{ 0, '+', 1 },
		{ 0, '-', 1 },
		{ 2, '.', 3 },
		{ 2, 'e', 5 },
		{ 2, 'E', 5 },
		{ 4, 'e', 5 },
		{ 4, 'E', 5 },
		{ 5, '+', 6 },
		{ 5, '-', 6 },
	});

	char[] numbers = "0123456789";
	float_checker.add_bulk_transitions({
		{ 0, numbers, 2 },
		{ 1, numbers, 2 },
		{ 2, numbers, 2 },
		{ 3, numbers, 4 },
		{ 4, numbers, 4 },
		{ 5, numbers, 7 },
		{ 6, numbers, 7 },
		{ 7, numbers, 7 },
	});

	return float_checker;
}

fn void main(String[] args) {
	Automaton float_checker = create_float_checker(tmem);

	foreach (arg : args[1..]) {
		io::printfn(
			"Float '%s' is valid: %s.",
			arg, automaton::run(&float_checker, arg, print_progress: false)!!
		);
	}
}
