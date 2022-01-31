## AzureDevOpsBotComposerFrameworkCICD

* Bot Framework Composer, built on the Bot Framework SDK, is an open-source IDE for developers to author, test, provision and manage conversational experiences. 
  It provides a powerful visual authoring canvas enabling dialogs, language-understanding models, QnAMaker knowledgebases and language generation responses to be authored from   within one canvas and crucially, enables these experiences to be extended with code for more complex tasks such as system integration. Resulting experiences can then be  tested within Composer and provisioned into Azure along with any dependent resources. For more details on Bot Composer, please look into the documentation at   https://docs.microsoft.com/en-us/composer/introduction?tabs=v2x 

* Composer developers can use this CI/CD pipeline to easily deploy new versions of their bots. Using Composer and Azure DevOps developers can seamlessly deliver their software updates.

* The Existing CICD approach can he found at https://github.com/gabog/ComposerCICDSamples . This pipeline has only build pipeline and no release pipeline with single stage deployment. 

## Advantages

This sample code will enhance the existing CICD Pipeline for Bot Composer Framework further in the following ways: 
  
  a. Multi stage deployments are implemented for multiple environments.  
  
  b. Importing the existing Knowledge Bases (KB) into the repository while deployment instead of manually adding the file. 
  
  c. Enhances the QnA Maker deployment. 
  
  d. Gives user the option to either deploy only web appliaction or the model files of LUIS and QnA Maker if required 
  
  e. Implements further security by demostrating how to pass key vault value to the app settings in the bot's application configuration 
  
  f. Also this solution fixes a bug in the existing approach as stated in https://github.com/gabog/ComposerCICDSamples/pull/7 . The code fixes the "Cannot find path
    '/home/vsts/work/1/s/dialogs...' because it does not exist" from occurring due to the recognizers having names as substrings of another recognizer.
