def getFolderName() {
  def array = pwd().split("/")
  return array[array.length - 2];
}
pipeline {
    agent { label 'databricks-agent' }
  environment {

    BRANCHES = "${env.GIT_BRANCH}"
    RELEASE_NAME = "databricks"
    ACTION = "${ACTION}"
    foldername = getFolderName()
    //databrick constants
    def GITREPO         = "${env.workspace}"
    def SCRIPTPATH      = "${GITREPO}/Automation/Deployments"
    def NOTEBOOKPATH    = "${GITREPO}/Workspace"
    def LIBRARYPATH     = "${GITREPO}/Libraries"
    def BUILDPATH       = "${GITREPO}/Builds/${env.JOB_NAME}-${env.BUILD_NUMBER}"
    def OUTFILEPATH     = "${BUILDPATH}/Validation/Output"
    def TESTRESULTPATH  = "${BUILDPATH}/Validation/reports/junit"
    def DBURL           = "${DATABRICKS_URL}"
    def DBTOKEN         = "${DATABRICKS_TOKEN_ID}"
    def CLUSTERID       = "${DATABRICKS_CLUSTER_ID}"
    def ORGID           = "${DATABRICKS_ORG_ID}"
    def DBPORT          = "${DATABRICKS_PORT}"
    def WORKSPACEPATH   = "/Shared/${foldername}"
    def DBFSPATH        = "dbfs:/FileStore/${foldername}"
    def CONDAPATH       = "/home/ciuser/anaconda3"
    def CONDAENV        = "databricks"

  }
  stages {
    
    stage('Setup') {
      steps {
        echo "setup...${GITREPO}...with token:${DBTOKEN}"
        
        withCredentials([string(credentialsId: DBTOKEN, variable: 'TOKEN')]) {
        sh """#!/bin/bash
            # Configure Conda environment for deployment & testing
            source ${CONDAPATH}/bin/activate ${CONDAENV}
            echo "setting up databricks connect..."
            # Configure Databricks CLI for deployment
            echo "${DBURL}
            $TOKEN" | databricks configure --token

            # Configure Databricks Connect for testing
            echo "${DBURL}
            $TOKEN
            ${CLUSTERID}
            ${ORGID}
            15001" | databricks-connect configure
                        
           """
        }
      }
    }


    stage('Run Unit Tests') {
        steps{
          sh """#!/bin/bash

                # Enable Conda environment for tests
                source ${CONDAPATH}/bin/activate ${CONDAENV}

                # Python tests for libs
                python3 -m pytest --junit-xml=${TESTRESULTPATH}/TEST-libout.xml ${LIBRARYPATH}/python/dbxdemo/test*.py || true
             """
        }
    }

    stage('Package') {
        steps{
          sh """#!/bin/bash
    
                # Enable Conda environment for tests
                source ${CONDAPATH}/bin/activate ${CONDAENV}
    
                # Package Python library to wheel
                # add package path and script
             """
        }
    }
    
    stage('Build Artifact') {
      steps {        
        sh """mkdir -p "${BUILDPATH}/Workspace"
              mkdir -p "${BUILDPATH}/Libraries/python"
              mkdir -p "${BUILDPATH}/Validation/Output"
              
              cp "${GITREPO}"/Workspace/*.ipynb "${BUILDPATH}/Workspace"
              #Get modified files
              #git diff --name-only --diff-filter=AMR HEAD^1 HEAD | xargs -I '{}' cp --parents -r '{}' ${BUILDPATH}

              # Get packaged libs
              find "${LIBRARYPATH}" -name '*.whl' | xargs -I '{}' cp '{}' "${BUILDPATH}/Libraries/python/"

              # Generate artifact
              # tar -czvf Builds/latest_build.tar.gz ${BUILDPATH}
           """
        // archiveArtifacts artifacts: 'Builds/latest_build.tar.gz'
      }
    }
    

    stage('Deploy') {
      steps {        
        sh """#!/bin/bash
          # Enable Conda environment for tests
          source ${CONDAPATH}/bin/activate ${CONDAENV}

          # Use Databricks CLI to deploy notebooks
          databricks workspace import_dir --overwrite "${BUILDPATH}/Workspace" "${WORKSPACEPATH}"
          dbfs cp -r "${BUILDPATH}/Libraries/python" ${DBFSPATH}
       """
      }
    }

    stage('Run Integration Tests') {
      steps {   
          withCredentials([string(credentialsId: DBTOKEN, variable: 'TOKEN')]) {

          sh """python3 "${SCRIPTPATH}/executenotebook.py" --workspace=${DBURL}\
                          --token=$TOKEN\
                          --clusterid=${CLUSTERID}\
                          --localpath="${NOTEBOOKPATH}"/VALIDATION\
                          --workspacepath="${WORKSPACEPATH}"/VALIDATION\
                          --outfilepath="${OUTFILEPATH}"
             """
          }
        sh """
              sed -i -e 's|#ENV#|${OUTFILEPATH}|g' '${SCRIPTPATH}/evaluatenotebookruns.py'
              python3 -m pytest --junit-xml="${TESTRESULTPATH}/TEST-notebookout.xml" "${SCRIPTPATH}/evaluatenotebookruns.py" || true
           """
      }
    }

    stage('Report Test Results') {
      steps {        
        sh """find "${OUTFILEPATH}" -name '*.json' -exec gzip --verbose {} \\;
          touch "${TESTRESULTPATH}"/TEST-*.xml
        """
        junit "**/reports/junit/*.xml"
      }
    }
  }
}