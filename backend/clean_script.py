import sys

path = 'server.py'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace non-ASCII characters with empty string or space
clean_content = "".join(i if ord(i) < 128 else " " for i in content)

with open(path, 'w', encoding='utf-8') as f:
    f.write(clean_content)

print("Successfully cleaned server.py of non-ASCII characters.")
