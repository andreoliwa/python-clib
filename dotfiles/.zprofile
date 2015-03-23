# https://docs.docker.com/installation/mac/
$(boot2docker shellinit)

export VIRTUALENVWRAPPER_PYTHON=$(which python3)

github_create_pullrequest() {
    BRANCH_DESTINATION="master"
    if [ -n "$2" ]
    then
        BRANCH_DESTINATION=$2
    fi
     
    echo "Creating PR to:" $BRANCH_DESTINATION
    echo "You have 5 seconds to cancel"
    
    for i in `seq 1 5`;
    do
        sleep 1
        echo "."
    done
 
    if [ -n "$1" ]
    then
        git branch > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            REPO=`git config --get remote.origin.url`
            if [[ "$REPO" =~ "github.com" ]]
            then
                OWNER=`echo $REPO | sed s/git@github.com://g | sed 's/\/.*//g'`
                BRANCH=`git branch | sed -n '/\* /s///p'`
                echo "hub pull-request -i $1 -b $OWNER:$BRANCH_DESTINATION -h $OWNER:$BRANCH"
                hub pull-request -i $1 -b $OWNER:$BRANCH_DESTINATION -h $OWNER:$BRANCH
            else
                echo "This is not a GitHub repo"
            fi
        else
            echo "You are not under a git repo"
        fi
    else
        echo "You have to provide one parameter with the issue number"
    fi
}

# EatFirst Pull Request
alias epr="github_create_pullrequest"
