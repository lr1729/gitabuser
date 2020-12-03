# Create as many directories as you need for the git folders
declare -a directories=(
  ".gitone" 
  ".gittwo" 
  ".gitthree"
)

# The size limit of one repository before using another in bytes
sizelimit=96636714682

# Get number of repositories
repositories=${#directories[@]}

# Check for and create repositories if they don't exist
for (( i=1; i<${repositories}+1; i++ ));
do
  if [ ! -d ${directories[$i-1]} ]; then
    echo -n "Directory ${directories[$i-1]} DOES NOT exist. Create repository? (Y/n) "
    read answer
    if [ "$answer" != "${answer#[Yy]}" ] ;then
      tmp_dir=$(mktemp -d -t ci-XXXXXXXXXX)
      git init $tmp_dir
      mv $tmp_dir/.git ${directories[$i-1]}
      git --git-dir=${directories[$i-1]} checkout -b master
      echo -n "Enter a remote for the repository: "
      read answer
      git --git-dir=${directories[$i-1]} remote add origin ${answer}
    fi
  fi
done

# Find repository to upload to
for (( i=1; i<${repositories}+1; i++ ));
do
  if [ $(du -s ${directories[$i-1]} | cut -f1) -lt $sizelimit ]; then
    repository=${directories[$i-1]}
    break
  fi
done
if [ -z "$repository" ]; then
  echo "All repositories are full"
  exit 1
fi
echo Saving files to $repository

