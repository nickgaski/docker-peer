#CI-Management:

This repository contains CI Configuration for all repositories including fabric, fabric-cop, fabric-sdk-node, fabric-api,  fabric-busybox,  fabric-sdk-py,  fabric-baseimage and  fabric-sdk-java. All the CI configuration is prepared in Jenkins job builders to create Jenkins Jobs.

As part of CI process we create JJB's (Jenkins Job Builder) in YAML format and uses them to configure Jenkins jobs. JJB has flexible template system, so creating many similarly configured jobs is easy.

To contribute to ci-management repository, please follow below steps

##Clone this repo:

This repository is having Jenkins configuration for all the hyperledger projects. Below are the steps to clone this repository:

###Using SSH:

Get the below command from **ci-management** project in [Gerrit Projects](https://gerrit.hyperledger.org/r/#/admin/projects/). Modify LFID with your LFID username. Please follow this link to get LFID if you don't have one. [lf-account](http://hyperledger-fabric.readthedocs.io/en/latest/Gerrit/lf-account/)


`git clone ssh://<LFID>@gerrit.hyperledger.org:29418/ci-management && scp -p -P 29418 <LFID>@gerrit.hyperledger.org:hooks/commit-msg ci-management/.git/hooks/`

###Using HTTP

`git clone http://<LFID>@gerrit.hyperledger.org/r/a/ci-management`

##Jenkins Sandbox Process:

The Linux Foundation Jenkins Sandbox purpose is to allow projects to test developers JJB setups before submitting code to the hyperledger ci-management repository. Hyperledger Jenkins Sandbox environment is configured similar to the production environment, although it cannot vote in Gerrit. To use Sandbox Jenkins, please follow this link [Jenkins Sandbox Process] (link)


Continuous Integration process using Jenkins CI server is implemented for all the projects under Hyperledger contodium. All users having LFID can can access Production Jenkins CI here [Jenkins](https://jenkins.hyplerledger.org). Below is the process we have implemented for each project.

##Fabric: 

When a user submits a commit to [fabric](https://gerrit.hyperledger.org/r/#/admin/projects/fabric) repository, Hyperledger Community Jenkins triggers verify jobs on x86_64, s390x and ppc64le environments [fabric-verify-x86_64](https://jenkins.hyperledger.org/view/fabric/job/fabric-verify-x86_64/), [fabric-verify-s390x](https://jenkins.hyperledger.org/view/fabric/job/fabric-verify-z/) and [fabric-verify-ppc64le](https://jenkins.hyperledger.org/view/fabric/job/fabric-verify-power-ppc64le/) and runs on minions available on each platform. As part of CI process on fabric repository we run **code-checks** and **unit-tests** on docker containers. 

Once the tests are executed successfully Jenkins publish Voting +1 to commit on the gerrit commit request as (+1 Hyperledger Jobbuilder) otherwise -1 (+1 Hyperledger Jobbuilder). Upon successful code review is done by the maintainers and merge the commit, Jenkins triggers merge jobs on x86_64, s390x and ppc64le platforms [fabric-merge-x86_64](https://jenkins.hyperledger.org/view/fabric/job/fabric-merge-x86_64/), [ fabric-merge-power-ppc64le](https://jenkins.hyperledger.org/view/fabric/job/fabric-merge-power-ppc64le/) and [fabric-merge-power-ppc64le](https://jenkins.hyperledger.org/view/fabric/job/fabric-merge-power-ppc64le/). Once the tests are executes successfully Jenkins publish code coverage report and artifacts if any on Jenkins console output. Jenkins supports cobertura code coverage report to display the go code coverage.

###Build Notifications:

Once the build is successfully executed, user should be able to view build result on Jenkins with Green bubble also can see the build status on https://github.com/hyperledger/fabric README documentation.

###*Trigger Builds through commits*:

re-verification of builds in possible in Jenkins. Developer has to type **reverify** or **recheck** in gerrit commit. Follow the below process to do this.

Step 1: Open gerrit commit for which you want to reverify or recheck the build

Step 2: Click on **Reply** and type **recheck** or **reverify** and click **Post**

After build is triggered, verify the Jenkins Console Output and go through the log messages if you are interested in knowing how the build is making progress.

###*Skip the build*:

Skipping the build is possible in Jenkins for readme or WIP patch sets. Very useful feature to skip the unnecessary builds and save resources. Follow below process to do this.

Step 1: Add [ci skip] in the commit description. Please avoid adding [ci skip] in commit message (First Line) instead add the same in commit description (Body of the commit message)

After commit is pushed to gerrit, now Jenkins triggers the build but it will not built. Jenkins notify "NOT BUILT" in gray bubble in Jenkins console output.
