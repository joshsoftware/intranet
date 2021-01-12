GENDER = ['Male', 'Female']
ADDRESSES = ['Permanent Address', 'Temporary Address']
BLOOD_GROUPS = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
STATUS = {created: 'created', pending: 'pending', approved: 'approved', resigned: 'resigned'}
LEAVE_STATUS = ['Pending', 'Approved', 'Rejected']
INVALID_REDIRECTIONS = ["/users/sign_in", "/users/sign_up", "/users/password"]
TSHIRT_SIZE = ['XS', 'S', 'M', 'L', 'XL', 'XXL', 'XXXL']
OTHER = ['DevOps', 'QA-Automation', 'QA-Manual', 'UI/UX']
LANGUAGE = ['Go', 'Python', 'Ruby', 'Java', 'PHP', 'Android', 'iOS']
FRAMEWORK = ['ReactJs', 'Angular', 'Flutter', '.Net', 'NodeJs']
PENDING = 'Pending'
APPROVED = 'Approved'
REJECTED = 'Rejected'
LOCATIONS = ['Bengaluru', 'Plano', 'Pune']
COUNTRIES = ['India', 'USA']
COUNTRIES_ABBREVIATIONS = ['IN', 'US']
CityCountryMapping = [
  { city: 'Bengaluru', country: 'India'},
  { city: 'Pune', country: 'India'},
  { city: 'Plano', country: 'USA'}
]

UI_UX_DESIGNATION = ['UI/UX Lead', 'UI/UX Designer', 'Senior UI/UX Designer']
ORGANIZATION_DOMAIN = 'joshsoftware.com'
ORGANIZATION_NAME = 'Josh Software'

CONTACT_ROLE =  ["Accountant", "Technical", "Accountant and Technical"]

SLACK_API_TOKEN = ENV['SLACK_API_TOKEN']

ROLE = { admin: 'Admin', employee: 'Employee', HR: 'HR', manager: 'Manager',
         intern: 'Intern', team_member: 'team member', consultant: 'Consultant',
         finance: 'Finance' }

DIVISION_TYPES = {
  consultant: 'Consultant', digital: 'Digital', management: 'Management', project: 'Projects'
}

EMAIL_ADDRESS = /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i

DEFAULT_TIMESHEET_MANAGERS = []

MANAGEMENT = ['Admin', 'HR', 'Manager', 'Finance']
TIMESHEET_MANAGEMENT = ['Admin', 'HR', 'Manager']

DOCUMENT_MANAGEMENT = ['Super Admin', 'Admin', 'HR']

DAILY_OFFICE_ENTRY_LIMIT = 30

OFFICE_ENTRY_PASS_MAIL_RECEPIENT=["shailesh.kalekar@joshsoftware.com", "sameert@joshsoftware.com", "hr@joshsoftware.com"]

ROLLBAR_ISSUES_URL = 'https://api.rollbar.com/api/1/items'
