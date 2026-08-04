from collections import Counter

state_w = 6
num_states = 47

trans_flat = []
with open("transition.mem") as f:
    for line in f:
        line = line.strip()
        if line:
            trans_flat.append(int(line, 16))

test = (b"attack" + b"Z"*19 + b"cmd.exe" + b"Z"*8 + b"malware")

access_count = Counter()
s = 0
for byte in test:
    access_count[s] += 1
    s = trans_flat[s * 256 + byte]

top8 = [st for st, _ in access_count.most_common(8)]
print("Top 8 states:", top8)
print("Counts:", [(st, access_count[st]) for st in top8])

hot = 0
for i, st in enumerate(top8):
    hot |= (st << (i * state_w))
print(f"HOT_STATES = 48'h{hot:012X}")