import math
from collections import deque

class AhoCorasick:
    def __init__(self):
        self.goto = [{}]
        self.fail = [0]
        self.output = [set()] 
        self.num_states = 1
        self.patterns = []
        self._built = False

    def add_pattern(self, pattern):
        #pattern IDs are 1-indexed
        pid = len(self.patterns) + 1
        self.patterns.append(pattern)
        data = pattern.encode() if isinstance(pattern, str) else bytes(pattern)

        state = 0
        for byte in data:
            if byte not in self.goto[state]:
                self.goto[state][byte] = self.num_states
                self.goto.append({})
                self.fail.append(0)
                self.output.append(set())
                self.num_states += 1
            state = self.goto[state][byte]
        self.output[state].add(pid)

    def build(self):
        assert not self._built, "build() already called"
        queue = deque()

        for byte in range(256):
            if byte in self.goto[0]:
                self.fail[self.goto[0][byte]] = 0
                queue.append(self.goto[0][byte])
            else:
                self.goto[0][byte] = 0

        while queue: #BFS lol
            r = queue.popleft()
            for byte in range(256):
                if byte in self.goto[r]:
                    s = self.goto[r][byte]
                    self.fail[s] = self.goto[self.fail[r]][byte]
                    self.output[s] |= self.output[self.fail[s]]
                    queue.append(s)
                else:
                    self.goto[r][byte] = self.goto[self.fail[r]][byte]

        self.table = [
            [self.goto[s][b] for b in range(256)]
            for s in range(self.num_states)
        ]
        #for hardware match table: lowest pattern ID wins if multiple match at same state
        self.match = [
            min(self.output[s]) if self.output[s] else 0
            for s in range(self.num_states)
        ]
        self._built = True

    def search(self, text):
        assert self._built, "call build() first"
        data = text.encode() if isinstance(text, str) else bytes(text)
        state = 0
        results = []
        for i, byte in enumerate(data):
            state = self.table[state][byte]
            for pid in self.output[state]:
                results.append((i, pid, self.patterns[pid - 1]))
        return results

    def state_width_bits(self):
        if self.num_states <= 1:
            return 1
        return math.ceil(math.log2(self.num_states))

    def write_mem(self, trans_path, match_path):
        assert self._built, "call build() first"
        hex_digits = math.ceil(self.state_width_bits() / 4)
        fmt = f'{{:0{hex_digits}X}}'

        #RTL access: trans_table[current_state * 256 + byte_in]
        with open(trans_path, 'w') as f:
            for state in range(self.num_states):
                for byte in range(256):
                    f.write(fmt.format(self.table[state][byte]) + '\n')

        with open(match_path, 'w') as f:
            for state in range(self.num_states):
                f.write(f'{self.match[state]:02X}\n')

        kb = self.num_states * 256 * self.state_width_bits() / 8 / 1024
        print(f'states      : {self.num_states}')
        print(f'state width : {self.state_width_bits()} bits')
        print(f'table size  : {kb:.1f} KB')
        print(f'wrote {trans_path} ({self.num_states * 256} entries)')
        print(f'wrote {match_path} ({self.num_states} entries)')


def load_patterns(path):
    with open(path) as f:
        return [
            line.strip() for line in f
            if line.strip() and not line.startswith('#')
        ]


def run_tests(ac):
    tests = [
        (
            "GET /../../etc/passwd HTTP/1.1",
            {"../../", "passwd"}
        ),
        (
            "<script>alert(1)</script>",
            {"<script>"}
        ),
        (
            "normal traffic nothing to see here",
            set()
        ),
        (
            "attack detected, running cmd.exe, found malware",
            {"attack", "cmd.exe", "malware"}
        ),
    ]

    all_pass = True
    for text, expected in tests:
        found = {m[2] for m in ac.search(text)}
        if found != expected:
            print(f'FAIL: "{text}"')
            print(f'  expected : {expected}')
            print(f'  got      : {found}')
            all_pass = False
        else:
            print(f'PASS: "{text}"')
    return all_pass


if __name__ == '__main__':
    patterns = load_patterns('patterns.txt')
    print(f'loaded {len(patterns)} patterns\n')

    ac = AhoCorasick()
    for p in patterns:
        ac.add_pattern(p)
    ac.build()

    print('--- validation ---')
    if run_tests(ac):
        print('\nall tests passed')
        print('\n--- writing mem files ---')
        ac.write_mem('transition.mem', 'match.mem')
    else:
        print('\ntests failed, not writing mem files')