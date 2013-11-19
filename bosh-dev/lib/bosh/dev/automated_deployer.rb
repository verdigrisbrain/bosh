require 'bosh/stemcell/archive'
require 'bosh/dev/bosh_cli_session'
require 'bosh/dev/director_client'

module Bosh::Dev
  class AutomatedDeployer
    # rubocop:disable ParameterLists
    def initialize(
      micro_target,
      bosh_target,
      build_number,
      deployment_account,
      artifacts_downloader
    )
      @micro_target = micro_target
      @bosh_target = bosh_target
      @build_number = build_number
      @deployment_account = deployment_account
      @artifacts_downloader = artifacts_downloader
    end
    # rubocop:enable ParameterLists

    def deploy
      deployment_account.prepare

      stemcell_path = artifacts_downloader.download_stemcell(build_number)
      stemcell_archive = Bosh::Stemcell::Archive.new(stemcell_path)
      micro_director_client.upload_stemcell(stemcell_archive)

      release_path = artifacts_downloader.download_release(build_number)
      micro_director_client.upload_release(release_path)

      manifest_path = deployment_account.manifest_path
      micro_director_client.deploy(manifest_path)

      bosh_director_client.upload_stemcell(stemcell_archive)
    end

    private

    attr_reader(
      :micro_target,
      :bosh_target,
      :build_number,
      :deployment_account,
      :artifacts_downloader,
    )

    def micro_director_client
      @micro_director_client ||= DirectorClient.new(
        uri: micro_target,
        username: deployment_account.bosh_user,
        password: deployment_account.bosh_password
      )
    end

    def bosh_director_client
      @director_client ||= DirectorClient.new(
        uri: bosh_target,
        username: deployment_account.bosh_user,
        password: deployment_account.bosh_password
      )
    end
  end
end
