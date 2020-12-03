# Create as many directories as you need for the git folders (2 minimum)
declare -a directories=(
  ".gitone" 
  ".gittwo" 
  ".gitthree"
)

# The size limit of one repository before using another in bytes
sizelimit=96636714682 # 90GB

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

# Find repository to upload new files to
for (( i=1; i<${repositories}+1; i++ ));
do
  # Check if the repository is empty
  if [ $(git --git-dir=${directories[$i-1]} count-objects | cut -d" " -f1) -eq 0 ]; then
    # If the first repository is empty set it as the location to push to
    if [ i=1 ]; then
      repository=${directories[$i-1]}
      break
    # if the previous repository is less than the maximum size set it as the location
    elif [ $(du -s ${directories[$i-2]} | cut -f1) -lt $sizelimit ]; then
      repository=${directories[$i-2]}
      break
    fi
  fi
done
# Use the last repository if it's less than the maximum size and there's no empty repositories
if [ -z "$repository" ]; then
  if [ $(du -s ${directories[${repositories}-1]} | cut -f1) -lt $sizelimit ]; then
    repository=${directories[${repositories}-1]}
    break
  else
    # Exit if all repositories are full
    echo "All repositories are full"
    exit 1
  fi
fi
echo Saving files to $repository

# Upload modified files for existing repositories
for (( i=1; i<${repositories}+1; i++ ));
do
  temp_file=$(mktemp)
  for file in $(git ls-files --modified --exclude-standard)
  do
    git add $file
    git commit -m "$file"
    git push -u origin master
  done
done

