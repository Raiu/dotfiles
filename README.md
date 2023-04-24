# dotfiles
### Bootstrap, prime and install
```sh:
sh -c "$(curl -fsSL https://raw.githubusercontent.com/Raiu/dotfiles/main/bootstrap.sh)"
```

### Prime the system:
```sh:
sh -c "$(curl -fsSL https://raw.githubusercontent.com/Raiu/dotfiles/main/prime.sh)"
```

### install dotfiles
```sh:
sh -c "$(curl -fsSL https://raw.githubusercontent.com/Raiu/dotfiles/main/install.sh)"
```
#
## Sub scripts

### Update package manager repositories

#### Ubuntu
```sh:
sh -c "$(curl -fsSL https://raw.githubusercontent.com/Raiu/dotfiles/main/setup/update-repo-ubuntu.sh)"
```
```sh:
sh -c "~/.dotfiles/setup/update-repo-ubuntu.sh"
```

#### Debian
```sh:
sh -c "$(curl -fsSL https://raw.githubusercontent.com/Raiu/dotfiles/main/setup/update-repo-debian.sh)"
```
```sh:
sh -c "~/.dotfiles/setup/update-repo-debian.sh"
```

#### Alpine
```sh:
sh -c "$(curl -fsSL https://raw.githubusercontent.com/Raiu/dotfiles/main/setup/update-repo-alpine.sh)"
```
```sh:
sh -c "~/.dotfiles/setup/update-repo-alpine.sh"
```


#
Exa
/usr/local/bin
/usr/local/share/man
/usr/local/share/zsh/site-functions