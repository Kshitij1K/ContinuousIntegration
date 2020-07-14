#!/usr/bin/python3
import sys

def ifLatestVersion(current_version, latest_version):
    return (current_version[0] > latest_version[0] or \
        (current_version[0] == latest_version[0] and current_version[1] > latest_version[1]) or \
        (current_version[0] == latest_version[0] and current_version[1] == latest_version[1] and current_version[2] > latest_version[2]))

def ifNextVersion(current_version, previous_version):
    possible_versions = [
        [previous_version[0], previous_version[1]+1, 0],
        [previous_version[0], previous_version[1], previous_version[2]+1],
        [previous_version[0]+1, 0, 0]
    ]

    return current_version in possible_versions

def main(arg):
    new_version = list(map (int, arg[1].split('.')))
    max_version = None
    prev_version = None

    num_args = len(arg)

    if num_args == 2 and new_version == [0, 0, 0]:
        print ("The version name is unique, and confirms to the semantic versioning system. Proceeding to build with this version as the tag.")
        return 0
    elif num_args == 2:
        print ("Looks like this is a new repository. Please start the versioning with '0.0.0'. Aborting.")
        print ("Or, run git commit with the '--no-verify' option to skip checking and building the Dockerfile, and pushing the image to DockerHub (Not recommended)") 
        return 1
    for i in range(2, len(arg)):
        i = arg[i].split('.')
        if (len(i) != 3):
            continue
        i = list(map(int, i))

        if new_version == i:
            print ("The version name is not unique and already exists on server. Aborting. Give a unique version and try again.")
            print ("Or, run git commit with the '--no-verify' option to skip checking and building the Dockerfile, and pushing the image to DockerHub (Not recommended)") 
            return 1
        if max_version == None or ifLatestVersion(i, max_version):
            max_version = i
        if (prev_version == None and ifNextVersion(new_version, i)) or (ifNextVersion(new_version, i) and ifLatestVersion(i, prev_version)):
            prev_version = i

    print ("The latest version currently is ", max_version[0], ".", max_version[1], ".", max_version[2], sep = '')

    if prev_version == None:
        print ("Version name is unique, however it does not follow the semantic versioning system. Here is a list of versions already on the server:-")
        print (arg[2:])
        print ("Please make sure the version number you specify fits into this semantic versioning system, and try again.")
        print ("Or, run git commit with the '--no-verify' option to skip checking and building the Dockerfile, and pushing the image to DockerHub (Not recommended)") 
        return 1

    if prev_version == max_version:
        print ("The version name is unique, and confirms to the semantic versioning system. Proceeding to build with this version as the tag.")
        return 0
    
    print ("The version name is unique, and confirms to the semantic versioning system.")
    print ("However, this version is behind the latest version, which is ", max_version[0], ".", max_version[1], ".", max_version[2], sep='')
    print ("This version will go directly ahead of ", prev_version[0], ".", prev_version[1], ".", prev_version[2], sep='')
    return 2

if __name__ == "__main__":
    sys.exit(main(sys.argv))