module Bosh::Director
  module Api
    class DeploymentManager
      include ApiHelper

      # Finds deployment by name
      # @param [String] name
      # @return [Models::Deployment] Deployment model
      # @raise [DeploymentNotFound]
      def find_by_name(name)
        DeploymentLookup.new.by_name(name)
      end

      def create_deployment(username, deployment_manifest_file_path, cloud_config, runtime_config, options = {})
        cloud_config_id = cloud_config.nil? ? nil : cloud_config.id
        runtime_config_id = runtime_config.nil? ? nil : runtime_config.id
        JobQueue.new.enqueue(username, Jobs::UpdateDeployment, 'create deployment', [deployment_manifest_file_path, cloud_config_id, runtime_config_id, options])
      end

      def delete_deployment(username, deployment, options = {})
        JobQueue.new.enqueue(username, Jobs::DeleteDeployment, "delete deployment #{deployment.name}", [deployment.name, options])
      end

      def deployment_to_json(deployment)
        result = {
          'manifest' => deployment.manifest,
        }

        Yajl::Encoder.encode(result)
      end

      def deployment_instances_to_json(deployment)
        instances = []
        filters = {:deployment_id => deployment.id}
        Models::Instance.filter(filters).exclude(vm_cid: nil).each do |instance|
          instances << {
            'agent_id' => instance.agent_id,
            'cid' => instance.vm_cid,
            'job' => instance.job,
            'index' => instance.index,
            'id' => instance.uuid
          }
        end

        Yajl::Encoder.encode(instances)
      end
    end
  end
end
