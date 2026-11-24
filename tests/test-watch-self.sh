#!/bin/bash
source "$(cd "$(dirname "$0")" && pwd)/harness.sh"

RULES="$SCRIPT_DIR/../watches/watch-self.yml"
t() { run_test "$RULES" "$@"; }

echo "=== watch-self ==="

echo "--- block: shell writes to lookout state ---"
t "append to overrides"  block '{"tool_name":"Bash","tool_input":{"command":"echo \"watch-git: off\" >> ~/.claude/lookout/overrides.yml"}}'
t "overwrite overrides"  block '{"tool_name":"Bash","tool_input":{"command":"printf \"\" > $HOME/.claude/lookout/overrides.yml"}}'
t "rm overrides"         block '{"tool_name":"Bash","tool_input":{"command":"rm ~/.claude/lookout/overrides.yml"}}'
t "rm unattended marker" block '{"tool_name":"Bash","tool_input":{"command":"rm -f ~/.claude/lookout/unattended/abc123"}}'
t "mv overrides"         block '{"tool_name":"Bash","tool_input":{"command":"mv /tmp/o.yml /Users/me/.claude/lookout/overrides.yml"}}'
t "sed -i overrides"     block '{"tool_name":"Bash","tool_input":{"command":"sed -i \"\" \"s/block/off/\" ~/.claude/lookout/overrides.yml"}}'
t "tee overrides"        block '{"tool_name":"Bash","tool_input":{"command":"echo x | tee ~/.claude/lookout/overrides.yml"}}'
t "truncate decisions"   block '{"tool_name":"Bash","tool_input":{"command":"truncate -s 0 ~/.claude/lookout/decisions.jsonl"}}'
t "/bin/mv overrides"    block '{"tool_name":"Bash","tool_input":{"command":"/bin/mv ~/.claude/lookout/overrides.yml /tmp/x"}}'
t "/bin/cp overrides"    block '{"tool_name":"Bash","tool_input":{"command":"/bin/cp /tmp/x ~/.claude/lookout/overrides.yml"}}'
t "/usr/bin/tee overrides" block '{"tool_name":"Bash","tool_input":{"command":"/usr/bin/tee ~/.claude/lookout/overrides.yml"}}'
t "/bin/mv absolute path" block '{"tool_name":"Bash","tool_input":{"command":"/bin/mv /tmp/o.yml /Users/me/.claude/lookout/overrides.yml"}}'
t "/bin/rm marker"       block '{"tool_name":"Bash","tool_input":{"command":"/bin/rm -f ~/.claude/lookout/unattended/abc123"}}'
t "sudo /bin/cp overrides" block '{"tool_name":"Bash","tool_input":{"command":"sudo /bin/cp /tmp/x ~/.claude/lookout/overrides.yml"}}'
t "piped /usr/bin/tee"   block '{"tool_name":"Bash","tool_input":{"command":"echo x | /usr/bin/tee ~/.claude/lookout/overrides.yml"}}'
t ">| keeps its target"  block '{"tool_name":"Bash","tool_input":{"command":"echo x >| /Users/me/.claude/lookout/overrides.yml"}}'
t "legacy dir: rm"       block '{"tool_name":"Bash","tool_input":{"command":"rm ~/.claude/claudewatch/overrides.yml"}}'
t "legacy dir: append"   block '{"tool_name":"Bash","tool_input":{"command":"echo \"watch-git: off\" >> ~/.claude/claudewatch/overrides.yml"}}'

echo "--- block: loosening through the plugin's own scripts ---"
t "overrides set off"    block '{"tool_name":"Bash","tool_input":{"command":"python3 \"${CLAUDE_PLUGIN_ROOT}/scripts/overrides.py\" set watch-git \"git push\" off"}}'
t "overrides set ask"    block '{"tool_name":"Bash","tool_input":{"command":"python3 \"${CLAUDE_PLUGIN_ROOT}/scripts/overrides.py\" set watch-git \"git push --force\" ask"}}'
t "overrides set set off" block '{"tool_name":"Bash","tool_input":{"command":"python3 scripts/overrides.py set watch-secrets off"}}'
t "overrides reset"      block '{"tool_name":"Bash","tool_input":{"command":"python3 scripts/overrides.py reset watch-git"}}'
t "overrides reset all"  block '{"tool_name":"Bash","tool_input":{"command":"python3 scripts/overrides.py reset"}}'
t "overrides.py as program" block '{"tool_name":"Bash","tool_input":{"command":"/opt/cw/scripts/overrides.py reset watch-git"}}'
t "unattended off"       block '{"tool_name":"Bash","tool_input":{"command":"python3 \"${CLAUDE_PLUGIN_ROOT}/scripts/unattended.py\" off"}}'
t "plugin disable"       block '{"tool_name":"Bash","tool_input":{"command":"claude plugin disable lookout@chris-peterson"}}'
t "plugin uninstall"     block '{"tool_name":"Bash","tool_input":{"command":"claude plugin uninstall lookout"}}'
t "legacy plugin disable" block '{"tool_name":"Bash","tool_input":{"command":"claude plugin disable ClaudeWatch@chris-peterson"}}'

echo "--- block: Write/Edit of lookout state or settings that disable it ---"
t "Write overrides"      block '{"tool_name":"Write","tool_input":{"file_path":"/Users/me/.claude/lookout/overrides.yml","content":"watch-git: off\n"}}'
t "Write empty overrides" block '{"tool_name":"Write","tool_input":{"file_path":"/Users/me/.claude/lookout/overrides.yml","content":""}}'
t "Write legacy overrides" block '{"tool_name":"Write","tool_input":{"file_path":"/Users/me/.claude/claudewatch/overrides.yml","content":"watch-git: off\n"}}'
t "Edit overrides"       block '{"tool_name":"Edit","tool_input":{"file_path":"/Users/me/.claude/lookout/overrides.yml","old_string":"block","new_string":"off"}}'
t "Write settings disable" block '{"tool_name":"Write","tool_input":{"file_path":"/Users/me/.claude/settings.json","content":"{\"enabledPlugins\": {\"lookout@chris-peterson\": false}}"}}'
t "Write disableAllHooks" block '{"tool_name":"Write","tool_input":{"file_path":"/w/.claude/settings.local.json","content":"{\"disableAllHooks\": true}"}}'

echo "--- allow: reads, tightening, and unrelated files ---"
t "cat overrides"        allow '{"tool_name":"Bash","tool_input":{"command":"cat ~/.claude/lookout/overrides.yml"}}'
t "ls state dir"         allow '{"tool_name":"Bash","tool_input":{"command":"ls -la ~/.claude/lookout/ 2>/dev/null"}}'
t "overrides show"       allow '{"tool_name":"Bash","tool_input":{"command":"python3 \"${CLAUDE_PLUGIN_ROOT}/scripts/overrides.py\" show --json"}}'
t "overrides check"      allow '{"tool_name":"Bash","tool_input":{"command":"python3 scripts/overrides.py check"}}'
t "overrides set block"  allow '{"tool_name":"Bash","tool_input":{"command":"python3 scripts/overrides.py set watch-git \"git push\" block"}}'
t "rule name with off"   allow '{"tool_name":"Bash","tool_input":{"command":"python3 scripts/overrides.py set watch-x \"turn off thing\" block"}}'
t "unattended on"        allow '{"tool_name":"Bash","tool_input":{"command":"python3 \"${CLAUDE_PLUGIN_ROOT}/scripts/unattended.py\" on"}}'
t "unattended status"    allow '{"tool_name":"Bash","tool_input":{"command":"python3 scripts/unattended.py status"}}'
t "reset decisions"      allow '{"tool_name":"Bash","tool_input":{"command":"python3 \"${CLAUDE_PLUGIN_ROOT}/scripts/reset-decisions.py\""}}'
t "plugin list"          allow '{"tool_name":"Bash","tool_input":{"command":"claude plugin list"}}'
t "plugin disable other" allow '{"tool_name":"Bash","tool_input":{"command":"claude plugin disable beacon"}}'
t "Write repo watches"   allow '{"tool_name":"Write","tool_input":{"file_path":"/w/lookout/watches/watch-git.yml","content":"name: watch-git\n"}}'
t "Write settings enable" allow '{"tool_name":"Write","tool_input":{"file_path":"/Users/me/.claude/settings.json","content":"{\"enabledPlugins\": {\"lookout@chris-peterson\": true}}"}}'

print_results
