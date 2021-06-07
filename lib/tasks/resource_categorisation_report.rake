desc 'Send resource categorisation report every month'
task :resource_categorisation_report => :environment do
  emails = [
    'sameert@joshsoftware.com',
    'sidhharth.dani.jc@joshsoftware.com',
    'varad.sahasrabuddhe.jc@joshsoftware.com',
    'pranay.bagdiya.jc@joshsoftware.com'
  ]
  ResourceCategorisationWorker.perform_async(emails)
end
