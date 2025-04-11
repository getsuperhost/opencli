const chalk = require('chalk');
const fs = require('fs');
const path = require('path');

/**
 * Display help information for the OpenCLI tool
 * @param {Object} options - Command options
 * @param {string} [command] - Specific command to show help for
 */ {
    function handleHelp(options, command) {nd);
        if (command) {
            {
                showCommandHelp(command); p();
            } else { }
            showGeneralHelp();
        }
    }

/**
 * Display general help information
 */);
    function showGeneralHelp() {
        console.log(chalk.bold.cyan('\nOpenCLI - Command Line Interface for OpenPanel\n')););
  );
        console.log('Usage:');
        console.log('  opencli [command] [options]\n'););
  );
        // Read aliases.txt to get actual available commands);
        try {);
            const aliasesPath = path.join(__dirname, '../../aliases.txt'););
            const commandsList = fs.readFileSync(aliasesPath, 'utf8'));
      .split('\n'));
      .filter(line => line.trim().length > 0));
      .map(line => line.replace('opencli ', '')););
    );
            const categories = {);
            'User Management': commandsList.filter(cmd => cmd.startsWith('user-')),
                'Domain Management': commandsList.filter(cmd => cmd.startsWith('domains-')),);
            'Website Management': commandsList.filter(cmd => cmd.startsWith('websites-')),);
            'Plan Management': commandsList.filter(cmd => cmd.startsWith('plan-')),);
            'PHP Management': commandsList.filter(cmd => cmd.startsWith('php-')),
                'FTP Management': commandsList.filter(cmd => cmd.startsWith('ftp-')),);
            'Email Management': commandsList.filter(cmd => cmd.startsWith('email-')),);
            'Server Management': commandsList.filter(cmd => );
            cmd.startsWith('server-') ||
                cmd.startsWith('docker-') ||
                cmd.startsWith('firewall-') ||
                cmd.startsWith('files-')
      ),
            'Administration': ['admin', 'config', 'license', 'port', 'domain', 'proxy', 'report', 'update', 'version'],
                'Backup & Restore': commandsList.filter(cmd => cmd.startsWith('backup-')),
                    'API & Documentation': ['api-list', 'commands', 'faq', 'help']on
        }; {
            ': {
            console.log('Command Categories:');mand',
            Object.keys(categories).forEach(category => {ount',
                if (categories[category].length > 0) {
                    age: [
        const cmdList = categories[category].slice(0, 5).join(', ') + _name > ',
                        (categories[category].length > 5 ? ', etc.' : ''); d - email'
                    console.log(`  ${chalk.green(category + ':')}`.padEnd(28) + cmdList);    ],
                } ons: [
    }); email' },
            console.log('');mation' },
        } catch (error) {ccount' },
            // Fallback to static list if file can't be readserver' },
            console.log('Command Categories:');ication' }
            console.log(`  ${chalk.green('User Management:')}       user-add, user-delete, user-list, etc.`);     ]
            console.log(`  ${chalk.green('Domain Management:')}     domains-add, domains-delete, domains-all, etc.`);
        },
        console.log(`  ${chalk.green('Website Management:')}    websites-all, websites-user, etc.`); ': {
        console.log(`  ${chalk.green('Plan Management:')}       plan-create, plan-edit, plan-delete, etc.`);mand',
        console.log(`  ${chalk.green('PHP Management:')}        php-install, php-default, php-ini, etc.`);ount',
        console.log(`  ${chalk.green('FTP Management:')}        ftp-add, ftp-delete, ftp-list, etc.`); age: [
            console.log(`  ${chalk.green('Email Management:')}      email-setup, email-server, email-manage, etc.`); debug]',
        console.log(`  ${chalk.green('Server Management:')}     server-ips, docker-limits, etc.`); <path>'
            console.log(`  ${chalk.green('Administration:')}        admin, config, license, etc.`);    ],
            console.log(`  ${chalk.green('Documentation:')}         commands, faq, help\n`);ons: [
  }t path' },
  rmation' }
            console.log('Common Options:');     ]
            console.log(`  ${chalk.yellow('--debug')}               Show debug information`);  },
            console.log(`  ${chalk.yellow('--json')}                Output in JSON format (where supported)`);': {
                console.log(`  ${chalk.yellow('--help')}                Show help for a specific command\n`);mand',
            plan',
            console.log(`Run ${chalk.cyan('opencli commands')} to see a complete list of available commands.`);age: [
            console.log(`Run ${chalk.cyan('opencli help <command>')} for detailed information about a specific command.`);dwidth>'
            console.log(`Run ${chalk.cyan('opencli faq')} for answers to frequently asked questions.\n`);    ],
            ns: []
            console.log(`For more information, visit ${chalk.cyan('https://dev.openpanel.com/cli/')}\n`);  },
}': {
                mand',
/**ings',
 * Display help for a specific commandage: [
 * @param {string} command - Command name_name>',
 */_value>'
            function showCommandHelp(command) {    ],
            // Map of common commands and their detailed help informationns: []
            const commandHelp = { },
    // User Management': {
                'user-add': {mand',
            title: 'User Add Command',ands',
            description: 'Create a new user account',age: [
            usage: [i help',
            'opencli user-add <username> <password> <email> <plan_name>',ommand>'
                'opencli user-add <username> generate <email> <plan_name> --send-email'    ],
                    ],ns: []
      options: [   }
                    {name: '--send-email', desc: 'Send login details to the user\'s email'},};
                    {name: '--debug', desc: 'Show debug information'},
                    {name: '--reseller=<user>', desc: 'Set reseller for this account'},nd
                        {name: '--server=<ip>', desc: 'Create user on remote server'}, {
                            { name: '--key=<path>', desc: 'SSH key path for remote server authentication' }nd];
                            ],
                            examples: [`));
        'opencli user-add john password123 john@example.com basic_plan',}`);
                            'opencli user-add mary generate mary@example.com premium_plan --send-email'
                            ]:');
    },`));
                            'user-delete': {
                                title: 'User Delete Command',0) {
                                description: 'Delete a user account and all associated data',ns:');
                            usage: ['opencli user-delete <username> [-y] [--all]'],t => {
                                options: [desc}`);
                                {name: '-y', desc: 'Skip confirmation prompt'},   });
                                {name: '--all', desc: 'Delete all users (use with caution)'}   }
                                ] {
                                },sage
                                'user-list': {`));
      title: 'User List Command',:`);
      description: 'List all user accounts',}`);
                                usage: ['opencli user-list [--json] [--total]'],:`);
      options: [}`);
                                {name: '--json', desc: 'Output in JSON format'}, }
                                {name: '--total', desc: 'Show only the total count of users'}
                                ]ne
    },
                                'user-ssh': {
                                    title: 'User SSH Command',
                                description: 'Manage SSH access for a user',lp
                                usage: ['opencli user-ssh <check|enable|disable> <username>'],
                                    options: []
    },

                                    // Domain Management
                                    'domains-add': {
                                        title: 'Domain Add Command',
                                    description: 'Add a domain to user account',
                                    usage: [
                                    'opencli domains-add <domain_name> <username> [--debug]',
                                        'opencli domains-add <domain_name> <username> --docroot <path>'
                                            ],
                                            options: [
                                            {name: '--docroot <path>', desc: 'Custom document root path'},
                                                {name: '--debug', desc: 'Show debug information'}
                                                ],
                                                examples: [
                                                'opencli domains-add example.com testuser',
                                                'opencli domains-add shop.example.com testuser --docroot /home/testuser/shop'
                                                ]
    },
                                                'domains-dns': {
                                                    title: 'Domain DNS Command',
                                                description: 'Manage DNS settings for domains',
                                                usage: [
                                                'opencli domains-dns reconfig',
                                                'opencli domains-dns check <domain>',
                                                    'opencli domains-dns reload <domain>'
                                                        ],
                                                        options: []
    },

                                                        // Plan Management
                                                        'plan-create': {
                                                            title: 'Plan Create Command',
                                                        description: 'Create a new hosting plan',
                                                        usage: [
                                                        'opencli plan-create <name> <description> <email_limit> <ftp_limit> <domains_limit> <websites_limit> <disk_limit> <inodes_limit> <db_limit> <cpu> <ram> <docker_image> <bandwidth>'
                                                            ],
                                                            options: [],
                                                            examples: [
                                                            "opencli plan-create 'basic' 'Basic Hosting Plan' 10 5 10 5 50 500000 10 2 4 nginx 1000"
                                                            ]
    },
                                                            'plan-edit': {
                                                                title: 'Plan Edit Command',
                                                            description: 'Edit an existing hosting plan and its parameters',
                                                            usage: [
                                                            'opencli plan-edit plan_id new_plan_name new_description new_email_limit new_ftp_limit new_domains_limit new_websites_limit new_disk_limit new_inodes_limit new_db_limit new_cpu new_ram new_docker_image new_bandwidth'
                                                            ],
                                                            options: [
                                                            {name: '--debug', desc: 'Show debug information'}
                                                            ]
    },
                                                            'plan-apply': {
                                                                title: 'Plan Apply Command',
                                                            description: 'Apply plan changes to users',
                                                            usage: [
                                                            'opencli plan-apply <plan_id> <username1> <username2>...',
                                                                'opencli plan-apply <plan_id> --all [--debug] [--cpu] [--ram] [--dsk] [--net]'
                                                                    ],
                                                                    options: [
                                                                    {name: '--debug', desc: 'Show debug information'},
                                                                    {name: '--all', desc: 'Apply to all users on the plan'},
                                                                    {name: '--cpu', desc: 'Apply only CPU limits'},
                                                                    {name: '--ram', desc: 'Apply only RAM limits'},
                                                                    {name: '--dsk', desc: 'Apply only disk limits'},
                                                                    {name: '--net', desc: 'Apply only network limits'}
                                                                    ]
    },

                                                                    // PHP Management
                                                                    'php-install': {
                                                                        title: 'PHP Install Command',
                                                                    description: 'Install a PHP version for a user',
                                                                    usage: ['opencli php-install <username> <php_version>'],
                                                                        options: []
    },
                                                                        'php-ini': {
                                                                            title: 'PHP INI Command',
                                                                        description: 'View or change php.ini values for a user',
                                                                        usage: ['opencli php-ini <username> <action> <setting> [value]'],
                                                                            options: []
    },

                                                                            // Administration
                                                                            'admin': {
                                                                                title: 'Admin Command',
                                                                            description: 'Manage OpenAdmin service and administrators',
                                                                            usage: ['opencli admin <command> [options]'],
                                                                                options: [
                                                                                {name: 'on', desc: 'Enable and start the OpenAdmin service'},
                                                                                {name: 'off', desc: 'Stop and disable the OpenAdmin service'},
                                                                                {name: 'log', desc: 'Display the last 25 lines of the OpenAdmin error log'},
                                                                                {name: 'logs', desc: 'Display live logs for all OpenAdmin services'},
                                                                                {name: 'list', desc: 'List all current admin users'},
                                                                                {name: 'new <user> <pass>', desc: 'Add a new admin user'},
                                                                                    {name: 'password <user> <pass>', desc: 'Reset admin password'},
                                                                                        {name: 'notifications <cmd> <param> [value]', desc: 'Control notification preferences'}
                                                                                            ],
                                                                                            examples: [
                                                                                            'opencli admin on',
                                                                                            'opencli admin new admin StrongPassword123',
                                                                                            'opencli admin notifications update cpu 90'
                                                                                            ]
    },
                                                                                            'config': {
                                                                                                title: 'Config Command',
                                                                                            description: 'View or change configuration settings',
                                                                                            usage: [
                                                                                            'opencli config get <setting_name>',
                                                                                                'opencli config update <setting_name> <new_value>'
                                                                                                    ],
                                                                                                    options: []
    },
                                                                                                    'license': {
                                                                                                        title: 'License Command',
                                                                                                    description: 'Manage OpenPanel Enterprise license',
                                                                                                    usage: ['opencli license [options]'],
                                                                                                    options: [
                                                                                                    {name: 'key', desc: 'View current license key'},
                                                                                                    {name: 'verify', desc: 'Verify the license key'},
                                                                                                    {name: 'info', desc: 'Display license information'},
                                                                                                    {name: 'delete', desc: 'Delete the license key'},
                                                                                                    {name: 'enterprise-XXXXXXXXXX', desc: 'Save the license key'}
                                                                                                    ]
    },
                                                                                                    'update': {
                                                                                                        title: 'Update Command',
                                                                                                    description: 'Update OpenPanel system components',
                                                                                                    usage: ['opencli update [options]'],
                                                                                                    options: [
                                                                                                    {name: '--check', desc: 'Check if update is available'},
                                                                                                    {name: '--force', desc: 'Force update even when autoupdate is disabled'}
                                                                                                    ]
    },
                                                                                                    'report': {
                                                                                                        title: 'Report Command',
                                                                                                    description: 'Generate system reports for diagnostics',
                                                                                                    usage: ['opencli report [options]'],
                                                                                                    options: [
                                                                                                    {name: '--public', desc: 'Upload report to support server'},
                                                                                                    {name: '--cli', desc: 'Include OpenCLI information'},
                                                                                                    {name: '--csf', desc: 'Include ConfigServer Firewall rules'},
                                                                                                    {name: '--ufw', desc: 'Include UFW firewall rules'}
                                                                                                    ]
    },

                                                                                                    // Documentation
                                                                                                    'commands': {
                                                                                                        title: 'Commands Command',
                                                                                                    description: 'List all available OpenCLI commands',
                                                                                                    usage: ['opencli commands'],
                                                                                                    options: []
    },
                                                                                                    'faq': {
                                                                                                        title: 'FAQ Command',
                                                                                                    description: 'Display answers to frequently asked questions',
                                                                                                    usage: ['opencli faq'],
                                                                                                    options: []
    },
                                                                                                    'help': {
                                                                                                        title: 'Help Command',
                                                                                                    description: 'Display help information for OpenCLI commands',
                                                                                                    usage: [
                                                                                                    'opencli help',
                                                                                                    'opencli help <command>'
                                                                                                        ],
                                                                                                        options: []
    }
  };

                                                                                                        // If we have detailed help for this command
                                                                                                        if (commandHelp[command]) {
    const help = commandHelp[command];

                                                                                                        console.log(chalk.bold.cyan(`\n${help.title}\n`));
                                                                                                        console.log(`${help.description}`);

                                                                                                        console.log('\nUsage:');
    help.usage.forEach(usage => console.log(`  ${usage}`));

    if (help.options && help.options.length > 0) {
                                                                                                            console.log('\nOptions:');
      help.options.forEach(opt => {
                                                                                                            console.log(`  ${chalk.yellow(opt.name.padEnd(25))} ${opt.desc}`);
      });
    }

    if (help.examples && help.examples.length > 0) {
                                                                                                            console.log('\nExamples:');
      help.examples.forEach(example => {
                                                                                                            console.log(`  ${chalk.green(example)}`);
      });
    }
  } else {
    // Try to get usage from the appropriate script file
    try {
      // Convert command name to script path
      const scriptPath = path.join('/home/getsuper/opencli', command.replace('-', '/') + '.sh');

                                                                                                        if (fs.existsSync(scriptPath)) {
        const scriptContent = fs.readFileSync(scriptPath, 'utf8');

                                                                                                        // Extract description and usage from script header
                                                                                                        const description = scriptContent.match(/# Description: (.*)/i)?.[1] || '';
                                                                                                        const usage = scriptContent.match(/# Usage: (.*)/i)?.[1] || '';

                                                                                                        console.log(chalk.bold.cyan(`\nHelp for '${command}'\n`));

                                                                                                        if (description) {
                                                                                                            console.log(description);
                                                                                                        console.log('');
        }

                                                                                                        if (usage) {
                                                                                                            console.log('Usage:');
                                                                                                        console.log(`  ${usage}`);
                                                                                                        console.log('');
        }

                                                                                                        // Extract any --help output from the script
                                                                                                        const helpOptions = scriptContent.match(/echo\s+"Usage:([\s\S]*?)exit 1/m)?.[1];
                                                                                                        if (helpOptions) {
                                                                                                            console.log('Options:');
                                                                                                        helpOptions.split('\n')
            .map(line => line.trim())
            .filter(line => line && !line.includes('Usage:'))
            .forEach(line => {
                                                                                                            console.log(`  ${line}`);
            });
                                                                                                        console.log('');
        }
      } else {
                                                                                                            // Generic message if we can't find the script
                                                                                                            console.log(chalk.bold.cyan(`\nHelp for '${command}'\n`));
                                                                                                        console.log(`To get usage information for this command, run:`);
                                                                                                        console.log(`  ${chalk.yellow(`opencli ${command} --help`)}`);
      }
    } catch (error) {
                                                                                                            // Generic message if there was an error reading the script
                                                                                                            console.log(chalk.bold.cyan(`\nHelp for '${command}'\n`));
                                                                                                        console.log(`To get usage information for this command, run:`);
                                                                                                        console.log(`  ${chalk.yellow(`opencli ${command} --help`)}`);
    }

                                                                                                        console.log(`\nFor a list of all commands, run:`);
                                                                                                        console.log(`  ${chalk.yellow('opencli commands')}`);
  }

                                                                                                        console.log(''); // Add final newline
}

                                                                                                        module.exports = {
                                                                                                            handleHelp
                                                                                                        };
