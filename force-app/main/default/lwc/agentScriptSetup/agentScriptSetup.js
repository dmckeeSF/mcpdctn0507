import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { MANAGE_OPPORTUNITIES_AGENT, LOCAL_MANAGE_OPPORTUNITIES_AGENT } from './agentScriptsData';

export default class AgentScriptSetup extends LightningElement {

    packagedScript = MANAGE_OPPORTUNITIES_AGENT;
    demoScript = LOCAL_MANAGE_OPPORTUNITIES_AGENT;

    // Agent metadata for copy-paste
    agentName = 'Opportunity Manager';
    agentDeveloperName = 'Opportunity_Manager';
    agentDescription = 'AI agent that helps users create Salesforce Opportunities through natural conversation. Dynamically discovers available fields from configured field sets, collects values through guided dialogue, validates input, and creates opportunities with full field-level security. Supports multiple team configurations for Sales, Partners, and custom workflows.';

    handleCopyName() {
        this.copyToClipboard(this.agentName, 'Agent Name');
    }

    handleCopyDeveloperName() {
        this.copyToClipboard(this.agentDeveloperName, 'Developer Name');
    }

    handleCopyDescription() {
        this.copyToClipboard(this.agentDescription, 'Agent Description');
    }

    handleCopyPackaged() {
        this.copyToClipboard(this.packagedScript, 'Packaged Agent Script');
    }

    handleCopyDemo() {
        this.copyToClipboard(this.demoScript, 'Demo Agent Script');
    }

    copyToClipboard(text, scriptType) {
        // Modern clipboard API (primary method)
        if (navigator.clipboard && navigator.clipboard.writeText) {
            navigator.clipboard.writeText(text)
                .then(() => {
                    this.showSuccessToast(scriptType);
                })
                .catch(() => {
                    this.fallbackCopyToClipboard(text, scriptType);
                });
        } else {
            // Fallback method
            this.fallbackCopyToClipboard(text, scriptType);
        }
    }

    fallbackCopyToClipboard(text, scriptType) {
        const textArea = document.createElement('textarea');
        textArea.value = text;
        textArea.style.position = 'fixed';
        textArea.style.left = '-9999px';
        document.body.appendChild(textArea);
        textArea.select();

        try {
            document.execCommand('copy');
            this.showSuccessToast(scriptType);
        } catch (err) {
            this.showErrorToast();
        }

        document.body.removeChild(textArea);
    }

    showSuccessToast(scriptType) {
        const event = new ShowToastEvent({
            title: 'Success',
            message: `${scriptType} copied to clipboard`,
            variant: 'success'
        });
        this.dispatchEvent(event);
    }

    showErrorToast() {
        const event = new ShowToastEvent({
            title: 'Error',
            message: 'Failed to copy to clipboard',
            variant: 'error'
        });
        this.dispatchEvent(event);
    }
}