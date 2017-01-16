#CI-Management:

This repository contains CI Configuration for all repositories including fabric, fabric-cop, fabric-sdk-node, fabric-api,  fabric-busybox,  fabric-sdk-py,  fabric-baseimage and  fabric-sdk-java. All the CI configuration is prepared in Jenkins job builders to create Jenkins Jobs.

As part of CI process we create JJB's (Jenkins Job Builder) in YAML format and uses them to configure Jenkins jobs. JJB has flexible template system, so creating many similarly configured jobs is easy.

To contribute to ci-management repository, please follow below steps

##Clone this repo:

This repository is having Jenkins configuration for all the hyperledger projects. Below are the steps to clone this repository:

###Using SSH:

Get the below command from **ci-management** project in [Gerrit Projects](https://gerrit.hyperledger.org/r/#/admin/projects/). Modify LFID with your LFID. Please follow this link to get LFID if you don't have one. [lf-account](http://hyperledger-fabric.readthedocs.io/en/latest/Gerrit/lf-account/)


`git clone ssh://<LFID>@gerrit.hyperledger.org:29418/ci-management && scp -p -P 29418 <LFID>@gerrit.hyperledger.org:hooks/commit-msg ci-management/.git/hooks/`

###Using HTTP

`git clone http://rameshthoomu@gerrit.hyperledger.org/r/a/ci-management`

##Jenkins Sandbox Process:

The Jenkins-sandbox purpose is to allow projects to test their JJB setups before submitting their code over to the hyperledger ci-management repository. Hyperledger Jenkins Sandbox environement is configured similarly to the production instance, although it cannot vote in Gerrit. [Jenkins Sandbox Process] (link)


Below is the process following for each repository:

##Fabric: 

When a user submits a commit to [fabric](https://gerrit.hyperledger.org/r/#/admin/projects/fabric) repository, jenkins triggers [fabric-verify-x86_64](https://jenkins.hyperledger.org/view/fabric/job/fabric-verify-x86_64/), [fabric-verify-s390x](https://jenkins.hyperledger.org/view/fabric/job/fabric-verify-z/) and [fabric-verify-ppc64le](https://jenkins.hyperledger.org/view/fabric/job/fabric-verify-power-ppc64le/) jobs in Jenkins and runs on minions. As part of CI process on fabric repository we run **code-checks** and **unit-tests** on docker containers. Once the tests are executes successfully Jenkins publish code coverage report and artifacts if any on Jenkins console output.

Once the tests are executed successfully Jenkins publish Voting +1 to commit on the gerrit as (+1 Hyperledger Jobbuilder) otherwise -1 (+1 Hyperledger Jobbuilder). Upon successful code review is done by the maintainers and merge the commit, Jenkins trigger [fabric-merge-x86_64](https://jenkins.hyperledger.org/view/fabric/job/fabric-merge-x86_64/), [ fabric-merge-power-ppc64le](https://jenkins.hyperledger.org/view/fabric/job/fabric-merge-power-ppc64le/) and [fabric-merge-power-ppc64le](https://jenkins.hyperledger.org/view/fabric/job/fabric-merge-power-ppc64le/). Once the tests are executes successfully Jenkins publish code coverage report and artifacts if any on Jenkins console output. 

###Build Notifications:

Once the build is successfully executed, user should be able to view build result on Jenkins with Green bubble also can see the build status on https://github.com/hyperledger/fabric README documentation.

###Trigger Builds through commits:

re-verification of builds in possible in Jenkins. Developer has to type **reverify** or **recheck** in gerrit commit. Follow the below process to do this.

Step 1: Open gerrit commit for which you want to reverify or recheck the build

Step 2: Click on **Reply** and type **recheck** or **reverify** and click **Post**

After build is triggered, verify the Jenkins Console Output and go through the log messages if you are interested in knowing how the build is making progress.
