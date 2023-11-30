---
title: tctl completion
description: Completion command
---

Generates tab completion scripts

```
tctl completion <bash|zsh|fish|powershell>
```

**Examples**

```

	Bash:
	
	$ source <(tctl completion bash)
	
	# To load completions for each session, execute once:
	Linux:
		$ tctl completion bash | sudo tee -a /etc/bash_completion.d/tctl > /dev/null
	MacOS:
		$ tctl completion bash | sudo tee -a $(brew --prefix)/etc/bash_completion.d/tctl > /dev/null
	
	Zsh:
	
	# If shell completion is not already enabled in your environment you will need
	# to enable it.  You can execute the following once:
	
	$ echo "autoload -U compinit; compinit" >> ~/.zshrc
	
	# To load completions for each session, execute once:
	$ tctl completion zsh > "${fpath[1]}/_tctl"
	
	# You will need to start a new shell for this setup to take effect.
	
	Fish:
	
	$ tctl completion fish | source
	
	# To load completions for each session, execute once:
	$ tctl completion fish > ~/.config/fish/completions/tctl.fish
		
```

**Options**

```
  -h, --help   help for completion
```

**Options inherited from parent commands**

```
  -c, --config string               Path to the config file to use. Can also be
                                    specified via TCTL_CONFIG env variable. This flag
                                    takes precedence over the env variable.
      --debug                       Print debug messages for all requests and responses
      --disable-tctl-version-warn   If set, disable the outdated tctl version warning. Can also be
                                    specified via TCTL_DISABLE_VERSION_WARN env variable.
  -p, --profile string              Use specific profile (default "default")
```

