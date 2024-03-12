# Role-Based Directory Access Control Script

This script is designed to manage access control to directories based on roles. It allows you to define roles and their associated directories, create these directories, delete directories, create groups for each role, set directory permissions for each role, and modify permissions of any directories.

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes.

### Prerequisites

You need to have `bash` installed on your system to run this script. If not installed, you can install it using the following command:

```
sudo apt-get install bash
```

### Installing

Clone the repository to your local machine:

```
git clone https://github.com/VladBlackbird/RoleBasedDirectoryAccessControl.git
```

Navigate to the project directory:

```
cd RoleBasedDirectoryAccessControl
```
Make the script executable:

```
chmod +x roleBasedDirectoryAccessControl.sh
```

### Usage

The script can be run with the following command:

```
./roleBasedDirectoryAccessControl.sh
```

The script will ask you to enter roles, directories for each role, whether you want to create these directories, whether you want to delete any directories, and whether you want to modify permissions of any directories. It will then create groups for each role and set directory permissions for each role.

## Built With

- Bash: The GNU Project's shell

## Authors

* **VladBlackbird** - *Initial work* - [VladBlackbird](https://github.com/VladBlackbird)

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details

## Acknowledgements

This script uses the Bash shell. We would like to acknowledge and thank the creators of this tool.