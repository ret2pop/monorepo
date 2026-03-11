import sys, re, hashlib, base64
html = open(sys.argv[1]).read()
match = re.search(r'<style[^>]*>(.*?)</style>', html, re.DOTALL | re.IGNORECASE)
if match:
    content = match.group(1).encode('utf-8')
    print(base64.b64encode(hashlib.sha256(content).digest()).decode())
    exit(0)
else:
    print('Error: Still could not find a <style> tag in the HTML.')
    exit(1)
