# Create as many directories as you need for the git folders
declare -a directories=(
  ".gitone" 
  ".gittwo" 
  ".gitthree"
)

# Get number of repositories
repositories=${#directories[@]}

for (( i=1; i<${repositories}+1; i++ ));
do
  if [ ! -d ${directories[$i-1]} ]; then
    echo -n "Directory ${directories[$i-1]} DOES NOT exist. Create repository? (Y/n) "
    read answer
    if [ "$answer" != "${answer#[Yy]}" ] ;then
      git init .
      mv .git ${directories[$i-1]}
      git --git-dir=${directories[$i-1]} checkout -b master
      echo -n "Enter a remote for the repository: "
      read answer
      git --git-dir=${directories[$i-1]} remote add origin ${answer}
    fi
  fi
done

