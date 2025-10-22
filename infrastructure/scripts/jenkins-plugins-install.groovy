/*
 * Jenkins Plugin Installation Script
 *
 * Go to: Manage Jenkins > Script Console
 * Paste this script and click "Run"
 *
 * This will install all required plugins for the CI/CD pipeline
 */

import jenkins.model.Jenkins
import java.util.logging.Logger

def logger = Logger.getLogger("")
def installed = false
def initialized = false

def pluginList = [
    "git",
    "github",
    "github-branch-source",
    "pipeline-stage-view",
    "docker-workflow",
    "docker-plugin",
    "kubernetes",
    "kubernetes-cli",
    "workflow-aggregator",
    "pipeline-maven",
    "maven-plugin",
    "aws-credentials",
    "aws-java-sdk",
    "credentials-binding",
    "ssh-agent",
    "junit",
    "jacoco",
    "sonar",
    "cloudbees-disk-usage-simple",
    "timestamper",
    "ws-cleanup",
    "build-timeout",
    "ansicolor"
]

logger.info("Installing plugins...")

def instance = Jenkins.getInstance()
def pm = instance.getPluginManager()
def uc = instance.getUpdateCenter()

pluginList.each { pluginName ->
    logger.info("Checking plugin: ${pluginName}")

    if (!pm.getPlugin(pluginName)) {
        logger.info("Installing plugin: ${pluginName}")
        def plugin = uc.getPlugin(pluginName)

        if (plugin) {
            plugin.deploy()
            installed = true
        } else {
            logger.warning("Plugin not found in update center: ${pluginName}")
        }
    } else {
        logger.info("Plugin already installed: ${pluginName}")
    }
}

if (installed) {
    logger.info("Plugins installed successfully!")
    logger.info("Jenkins will restart in 10 seconds to activate plugins...")

    // Schedule restart
    instance.safeRestart()
} else {
    logger.info("All plugins were already installed. No restart needed.")
}

return "Plugin installation complete. Check console output above for details."
