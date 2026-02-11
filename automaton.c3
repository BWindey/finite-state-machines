module automaton;
import std::io;

faultdef INVALID_STATE, INVALID_INPUT;

struct Automaton {
	char state_count;
	char start_state;
	char[] accepted_states;
	ichar[][] eda_table;

	ichar[128] alphabet_indices;

	Allocator allocator;
}

<*
	@require alphabet.len < 128
*>
fn void Automaton.init(
	&self, Allocator allocator,
	char state_count, char start_state,
	char[] alphabet, char[] accepted_states,
) {
	self.state_count = state_count;
	self.start_state = start_state;
	self.accepted_states = allocator::clone_slice(allocator, accepted_states);

	self.alphabet_indices = { [0..127] = -1 };
	foreach (char idx, char e : alphabet) {
		self.alphabet_indices[e] = idx;
	}

	self.eda_table = allocator::new_array(allocator, ichar[], state_count);

	for (usz i = 0; i < state_count; i++) {
		self.eda_table[i] = allocator::new_array(allocator, ichar, alphabet.len);
		mem::set(self.eda_table[i], (char) -1, char.sizeof * alphabet.len);
	}
}

fn void Automaton.tinit(
	&self,
	char state_count, char start_state,
	char[] alphabet, char[] accepted_states,
) {
	return self.init(tmem, state_count, start_state, alphabet, accepted_states);
}

<*
	Add a single transition.

	@require self.state_count != 0 : "Automaton has not been initialized yet (.init(...))"
*>
fn void? Automaton.add_transition(
	&self, char state, char input, char next_state
) @maydiscard {
	if (state >= self.state_count) return INVALID_STATE~;
	if (next_state >= self.state_count) return INVALID_STATE~;
	if (input >= 128) return INVALID_INPUT~;

	char index = self.alphabet_indices[input];

	self.eda_table[state][index] = next_state;
}

fn void? Automaton.add_transitions(&self, char[3][] triplets)  @maydiscard {
	foreach (triplet : triplets) {
		self.add_transition(...triplet)!;
	}
}

fn void? Automaton.add_bulk_transition(
	&self, char state, char[] inputs, char next_state
) @maydiscard {
	foreach (input : inputs) self.add_transition(state, input, next_state)!;
}

struct BulkTransition {
	char state;
	char[] input;
	char next_state;
}

fn void? Automaton.add_bulk_transitions(
	&self, BulkTransition[] bulk_transitions
) @maydiscard {
	foreach (transition : bulk_transitions) {
		self.add_bulk_transition(...transition)!;
	}
}

fn bool? run(
	Automaton* automaton, char[] input, bool print_progress = true
) {
	char current_state = automaton.start_state;

	foreach (char x : input) {
		if (x >= 128) return INVALID_INPUT~;
		ichar index = automaton.alphabet_indices[x];
		if (index < 0) return INVALID_INPUT~;

		ichar next_state = automaton.eda_table[current_state][index];

		if (print_progress) {
			if (x > 32 && x <= 126) {
				io::printfn(
					"Reading '%c', state transition: %d -> %d.",
					x, current_state, next_state
				);
			} else {
				io::printfn(
					"Reading 0x%x, state transition: %d -> %d.",
					x, current_state, next_state
				);
			}
		}

		if (next_state < 0) return false;
		current_state = next_state;
	}

	foreach (char accepted_state : automaton.accepted_states) {
		if (current_state == accepted_state) return true;
	}

	return false;
}
