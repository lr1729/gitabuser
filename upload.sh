#!/bin/bash
# Create as many directories as you need for the git folders (2 minimum)
declare -a directories=(
  ".gitone" 
  ".gittwo" 
  ".gitthree"
)

# The size limit of one repository before using another in bytes
sizelimit=80530595568 # 75GB

# Get number of repositories
repositories=${#directories[@]}

# Check for and create repositories if they don't exist
for (( i=1; i<${repositories}+1; i++ ));
do
  if [ ! -d ${directories[$i-1]} ]; then
    echo -n "Directory ${directories[$i-1]} DOES NOT exist. Create repository? (y/n) "
    read answer
    if [ "$answer" != "${answer#[Yy]}" ] ;then
      tmp_dir=$(mktemp -d)
      git init $tmp_dir
      mv $tmp_dir/.git ${directories[$i-1]}
      echo ${directories[$i-1]} >> .gitignore
      git --git-dir=${directories[$i-1]} checkout -b master
      echo -n "Enter a remote for the repository: "
      read answer
      git --git-dir=${directories[$i-1]} remote add origin ${answer}
      echo -n "Enter your git email: "
      read answer
      git --git-dir=${directories[$i-1]} config --global user.email "${answer}"
      echo -n "Enter your git username: "
      read answer
      git --git-dir=${directories[$i-1]} config --global user.name "${answer}"
    fi
  fi
done

# Find repository to upload new files to
for (( i=1; i<${repositories}+1; i++ ));
do
  # Check if the repository is empty
  if [ $(git --git-dir=${directories[$i-1]} count-objects | cut -d" " -f1) -eq 0 ]; then
    # If the first repository is empty set it as the location to push to
    if [ $i -eq 1 ]; then
      repository=${directories[$i-1]}
      reponum=$(($i-1))
      break
    # if the previous repository is less than the maximum size set it as the location
    elif [ $(du -sb ${directories[$i-2]} | cut -f1) -lt $sizelimit ]; then
      repository=${directories[$i-2]}
      reponum=$(($i-2))
      break
    fi
  fi
done
# Use the last repository if it's less than the maximum size and there's no empty repositories
if [ -z "$repository" ]; then
  if [ $(du -sb ${directories[${repositories}-1]} | cut -f1) -lt $sizelimit ]; then
    repository=${directories[${repositories}-1]}
    reponum=$(($i-1))
  else
    # Exit if all repositories are full
    echo "All repositories are full"
    exit 1
  fi
fi
echo "Current destination for new files is $repository"

# Upload modified/deleted files for existing repositories
echo "Updating existing repositories"
for (( i=1; i<${reponum}+1; i++ ));
do
  temp_file=$(mktemp)
  for file in $(git --git-dir=${directories[$i-1]} ls-files --modified --deleted --exclude-standard)
  do
    git --git-dir=${directories[$i-1]} add $file
    git --git-dir=${directories[$i-1]} commit -m "$file"
    git --git-dir=${directories[$i-1]} push -u origin master
  done
done

# Get the intersection of untracked files from all previous repositories
# These are the files that are not tracked by any repository to avoid duplicates
if [ $reponum -eq 0 ]; then
  intersection=$(git --git-dir=${directories[0]} ls-files --other --exclude-standard)
elif [ $reponum -eq 1 ]; then
  intersection=$(comm -12 <(git --git-dir=${directories[0]} ls-files --other --exclude-standard | sort) <(git --git-dir=${directories[1]} ls-files --other --exclude-standard | sort))
else
  intersection=$(comm -12 <(git --git-dir=${directories[0]} ls-files --other --exclude-standard | sort) <(git --git-dir=${directories[1]} ls-files --other --exclude-standard | sort))
  for (( i=2; i<${reponum}; i++ ));
  do
    intersection=$(comm -12<(echo -e "$intersection" | sort) <(git --git-dir=${directories[i]} ls-files --other --exclude-standard | sort))
  done
fi

# Upload the files to the previously determined destination
echo "Uploading new files to $repository"
for file in $(echo -e "$intersection")
do
  git --git-dir=$repository add $file
  git --git-dir=$repository commit -m "$file"
  git --git-dir=$repository push -u origin master
  # If the repository becomes too full restart the script
  if [ $(du -sb $repository | cut -f1) -gt $sizelimit ]; then
    $(basename $0) && exit
  fi
done
