##Jenkins Sandbox:

Hyperledger Jenkins Sandbox is to provide test instance of Jenkins Job builders before pushing Job templates to Production Jenkins UI. It is configured similar to the Hyperledger ci-management master instance, although it cannot publish artifacts or vote in Gerrit. This is just a test environment to create and test before you push changes to hyperledger fabric repository. Below are the points keep in mind before you work on Hyperledger Jenkins Sandbox environment for your experimental stuff.

- Jobs are automatically deleted every weekend
- Committers can login and configure Jenkins jobs in the sandbox directly
- Sandbox jobs can NOT upload build images to docker hub 
- Sandbox jobs can NOT vote on Gerrit
- Jenkins nodes are configured using Hyperledger openstack infrastructure.

Create Jenkins jobs and execute them in Sandbox environment. If you don't have gerrit account follow the steps mentioned here [**Gerrit**](http://hyperledger-fabric.readthedocs.io/en/latest/Gerrit/lf-account/)

If you don't have ci-management Jenkins Configuration repository please perform git clone from here **[ci-management]**(https://gerrit.hyperledger.org/r/#/admin/projects/ci-management)

`git clone ssh://<LFID>@gerrit.hyperledger.org:29418/ci-management && scp -p -P 29418 <LFID>@gerrit.hyperledger.org:hooks/commit-msg ci-management/.git/hooks/`

###Follow below steps to install JJB in your machine:

```
sudo apt-get install python-virtualenv
virtualenv hyp
source hyp/bin/activate
pip install 'jenkins-job-builder==1.5.0'
jenkins-jobs --version
jenkins-jobs test --recursive jjb/
```
### Make a copy of the example JJB config file (in the builder/ directory)

`cd ci-management`

take a backup of jenkins.ini.example to jenkins.ini

`cp jenkins.ini.example jenkins.ini`

After take a backup of jenkins.ini, modify jenkins.ini with the following details

**Note:** Update `jenkins.ini` file with your **Jenkins LFID username**, **API token** and **Hyperledger jenkins sandbox URL**

```
[job_builder]
ignore_cache=True
keep_descriptions=False
include_path=.:scripts:~/git/
recursive=True

[jenkins]
#user=jenkins
#password=1234567890abcdef1234567890abcdef
#url=http://localhost:8080
user=rameshthoomu <<your LFID username>
password=bbb779809e4669a013b627abca175ed7 <your LFID jenkins sandbox API Token>
url=https://jenkins.hyperledger.org/sandbox 
##### This is deprecated, use job_builder section instead
#ignore_cache=True
```
###How to get API token?
Login to the Jenkins Sandbox environment, go to your user page by clicking on your username, click “Configure” and then “Show API Token”.

You can see all projects job templates in jjb directory. To work on existing or create new jobs in `jjb` directory. Follow below commands to test, update or delete jobs in Sandbox environment.

##To Test a Job: 

After you modify or create jobs in the above environment it's a good practice to test the job before you update this job in Sandbox environment. 

`jenkins-jobs --conf jenkins.ini test jjb/ <job-name>`

**Example:** `jenkins-jobs --conf jenkins.ini test jjb/ fabric-verify-x86_64`

If the job you’d like to test is a template with variables in its name, it must be manually expanded before use. For example, the commonly used template **fabric-verify-{arch}** might expand to **fabric-verify-x86-64**

Successful tests output the XML description of the Jenkins job described by the specified JJB job name.

Execute the following command to pipeout to a directory

`jenkins-jobs --conf jenkins.ini test jjb/ <job-name> -o <directoryname>` The output directory will contain files with the XML configurations.

##To Update a Job:

Once you’ve configured your `jenkins.ini` and verified it using the above command to produce valid XML descriptions of Jenkins jobs. Upon successful verification of job execute below command to update job to Jenkins sandbox.

`jenkins-jobs --conf jenkins.ini update jjb/ <job-name>`

**Example:** `jenkins-jobs --conf jenkins.ini update jjb/ fabric-verify-x86_64`

##Trigger Jobs from Jenkins Sandbox:

Once you push the Jenkins job configuration to Hyperledger Sandbox environment run the job from Jenkins Sandbox webUI. Follow the below process to trigger the build:

Step 1: Login into [Jenkins Sandbox WebUI](https://jenkins.hyperledger.org/sandbox/)

Step 2: Click on the Job which you want to trigger then, Click “Build with Parameters” and then “Build”.

Step 3: Verify the "Build Executor Status" bar and make sure build is triggered on the available executor. In Sandbox you may not see all platforms build executors and you don't find many like in production CI environment. If you want to test any of the Hyperledger fabric repositories

Once the Job is triggered, click on the build number to see all the details about the job and view the console output.

## To Delete a Job:

Execute the below command to Delete a job from Sandbox:

`jenkins-jobs --conf jenkins.ini delete jjb/ <job-name>`

**Example** `jenkins-jobs --conf jenkins.ini delete jjb/ fabric-verify-x86_64`

Above command deletes the **fabric-verify-x86-64**

## Modify Existing Job:

In Hyperledger Jenkins sandbox, you can directly edit or modify the job configuration by selecting the Job name and click on "Configure" button. Click on "Apply" and "Save" button to save the Job. But As we are using JJB to create and publish jobs, better to use the same approach to "Modify" the Jobs. Modify the existing job on your terminal, and follow the steps mentioned above in **To Test a Job** and **To Update a Job**
