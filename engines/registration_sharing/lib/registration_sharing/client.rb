class RegistrationSharing::Client
  def initialize(peer, system_login)
    @peer = peer
    @system_login = system_login
  end

  def sync_system
    system = System.find_by(login: @system_login)
    if system
      peer_register_system(system)
    else
      peer_deregister_system
    end
  end

  protected

  def peer_register_system(system)
    params = {}

    %w[login password hostname registered_at created_at last_seen_at].each do |attribute|
      params[attribute] = system.send(attribute)
    end

    params[:activations] = system.activations.map do |a|
      { product_id: a.product.id, created_at: a.created_at }
    end

    make_request(:post, params)
  end

  def peer_deregister_system
    make_request(:delete, { login: @system_login })
  end

  def make_request(method, params)
    # TODO: CA path
    # TODO: user-agent

    request = Typhoeus::Request.new(
      "https://#{@peer}/api/regsharing",
      method: method,
      headers: {
        'Content-Type' => 'application/json',
        'Authorization' => "Bearer #{RegistrationSharing.config_api_secret}"
      },
      body: JSON.dump(params)
    )

    response = request.run

    unless response.success?
      raise "Regsharing request failed with code #{response.code}: #{response.body}"
    end

    response
  end

end
