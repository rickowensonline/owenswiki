Gollum::Page.send :remove_const, :FORMAT_NAMES if defined? Gollum::Page::FORMAT_NAMES

## Omni Auth
require 'omnigollum'
require 'omniauth/strategies/discord'

wiki_options = {
  :live_preview => true,
  :allow_uploads => true,
  :per_page_uploads => false,
  :page_file_dir => 'docs/',
  :critic_markup => true,
  :allow_editing => true,
  :css => true,
  :emoji => true,
  :display_metadata => false,
  :h1_title => true
}
Precious::App.set(:wiki_options, wiki_options)
Precious::App.set(:protection, :except => [:session_hijacking])

options = {
  :providers => Proc.new do
    provider :discord, ENV['DISCORD_CLIENT_ID'], ENV['DISCORD_CLIENT_SECRET'], scope: 'email identify'
  end,
  :dummy_auth => false,
  :protected_routes => ['/gollum/create/*'],
  :authorized_users => true,
  :author_format => Proc.new { |user| user.name },
  :author_email => Proc.new { |user| user.email },
}

## :omnigollum options *must* be set before the Omnigollum extension is registered
Precious::App.set(:omnigollum, options)
Precious::App.register Omnigollum::Sinatra

credentials = Rugged::Credentials::SshKeyFromAgent.new(username: 'git')

Gollum::Hook.register(:post_commit, :hook_id) do |committer, sha1|
  committer.wiki.repo.git.pull('origin', committer.wiki.ref, credentials: credentials)
  committer.wiki.repo.git.push('origin', committer.wiki.ref, credentials: credentials)
end

