GENDER = ['Male', 'Female']
ADDRESSES = ['Permanent Address', 'Temporary Address']
BLOOD_GROUPS = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
STATUS = ['created', 'pending', 'approved']
LEAVE_STATUS = ['Pending', 'Approved', 'Rejected']
INVALID_REDIRECTIONS = ["/users/sign_in", "/users/sign_up", "/users/password"]
TSHIRT_SIZE = ['XS', 'S', 'M', 'L', 'XL', 'XXL', 'XXXL']

PENDING = 'Pending'
APPROVED = 'Approved'
REJECTED = 'Rejected'

ORGANIZATION_DOMAIN = 'joshsoftware.com'
ORGANIZATION_NAME = 'Josh Software'

CONTACT_ROLE =  ["Accountant", "Technical", "Accountant and Technical"]

SLACK_API_TOKEN = ENV['SLACK_API_TOKEN']

ROLE = { admin: 'Admin', employee: 'Employee', HR: 'HR', manager: 'manager', intern: 'Intern', team_member: 'team member' }

EMAIL_ADDRESS = /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i

DEFAULT_TIMESHEET_MANAGERS = []

MANAGEMENT = ["Admin", "HR", "Manager", "Finance"]
TIMESHEET_MANAGEMENT = ['Admin', 'HR', 'Manager']
