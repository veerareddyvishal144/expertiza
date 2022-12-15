require './spec/support/teams_shared.rb'

describe TeamsRequestController do
   let(:user2) { build(:student, id: 2) }
   let(:user3) { build(:student, id: 3) }
   let(:assignment) { build(:assignment, id: 1) }
    let(:team) { build(:assignment_team, id: 1, parent_id: 1) }
    let(:team2) { build(:assignment_team, id: 2, parent_id: 1) }
    let(:topic) { build(:topic, id: 1, assignment_id: 1) }
    let(:signed_up_team) { build(:signed_up_team, is_waitlisted: true) }
  
    it { should belong_to :to_user }
    it { should belong_to :from_user }
  # Including the stubbed objects from the teams_shared.rb file
  include_context 'object initializations'
  # Including the shared method from the teams_shared.rb file
  include_context 'authorization check'
  # Testing action_allowed? controller
  context 'provides access to people with' do
    it 'will give students above access' do
      stub_current_user(student1, student1.role.name, student1.role)
      # Expecting students to be allowed access.
      expect(controller.send(:action_allowed?)).to be true
    end
  end

  # The Get Index test fails due to missing template
  # An issue in github is created for this problem.

  describe 'GET index' do
    context 'when the user does not have admin permissions' do
      it 'redirects to' do
        # Stubbing an object to receive .all method to give list of index
        allow(JoinTeamRequest).to receive(:all).and_return(join_team_request1)
        request_params = { action: 'index' }
        user_session = { user: ta }
        result = get :index, params: request_params, session: user_session
        expect(result.status).to eq 302
      end
    end
    context 'when the user does have admin permissions' do
      it 'routes to index page' do
        # Stubbing an object to receive .all method to give list of index
        allow(TeamsRequestController).to receive(:all).and_return(join_team_request1)
        request_params = { action: 'index' }
        user_session = { user: admin }
        result = get :index, params: request_params, session: user_session
        expect(result.status).to eq 200
      end
    end
  end
  # Testing show method to get the particular join team request
  describe 'GET #show' do
    context 'when show is valid' do
      it 'will show particular student team given index' do
        allow(JoinTeamRequest).to receive(:find).and_return(join_team_request2)
        request_params = { action: 'show' }
        user_session = { user: ta }
        result = get :show, params: request_params, session: user_session
        # status code 200: Request succeeded
        expect(result.status).to eq 200
      end
    end
  end

  # Testing new method to redirect to create a new join team request
  describe 'GET #new' do
    context 'when new is called' do
      it 'routes to #new page' do
        result = get :new, inv:0
        expect(result).to route_to('join_team_requests#new')
        result = get :new, inv: 1
        expect(result.status).to eq 200

      end
    end
  end

  # Testing create method to create a new join team request
  describe 'POST #create' do
    before(:each) do
      # Stubbing participant to receive an object with id = 1
      allow(Participant).to receive(:find).with('1').and_return(participant)
    end
    context 'when creating new join team request is not saved!' do
      it 'will render #new page' do
        allow(JoinTeamRequest).to receive(:new).and_return(invalidrequest)
        request_params = { participant_id: participant.id, team_id: -2 }
        user_session = { user: student1 }
        get :new, params: request_params, session: user_session
        expect(response).to render_template('new')
      end
    end
    # Testing when the object is being saved to the database
    context 'when resource is saved' do
      before(:each) do
        allow(JoinTeamRequest).to receive(:new).and_return(join_team_request2)
        allow(Team).to receive(:find).with('1').and_return(team1)
        allow(Assignment).to receive(:find).with(1).and_return(assignment1)
        allow(Participant).to receive(:where).with(user_id: 1, parent_id: '1').and_return([participant])
        allow(join_team_request2).to receive(:save).and_return(true)
      end
      it "will change the status to 'P' " do
        allow(join_team_request2).to receive(:save).and_return(true)
        request_params = {
          id: 2,
          join_team_request2: {
            status: 'P'
          },
          team_id: 1,
          assignment_id: 1
        }
        user_session = { user: student1 }
        post :create, params: request_params, session: user_session
        # status code 302: Redirect url
        expect(response.status).to eq 302
        expect(join_team_request2.status).to eq('P')
      end
    end
    context 'when it is not created' do
      it 'will page for new ' do
        allow(join_team_request2).to receive(:save).and_return(false)
        request_params = { action: 'new' }
        user_session = { user: student1 }
        get :new, params: request_params, session: user_session
        # status code 200: Request succeeded
        expect(response.status).to eq 200
      end
    end
  end
  # Testing the Update method
  describe 'PUT #update' do
    before(:each) do
      # Stubbing an object and allowing it to receive update_attributes method
      join_team_request2 = JoinTeamRequest.new
      allow(join_team_request2).to receive(:update_attributes).with(:comments).and_return(true)
      allow(Participant).to receive(:find).with('1').and_return(participant)
    end

    context 'when the join_team_request is updated' do
      it 'will update the :comments parameter only' do
        allow(Participant).to receive(:find).with('1').and_return(participant)
        allow(Team).to receive(:find).with('2').and_return(team2)
        request_params = {
          action: 'update',
          id: 2,
          join_team_request2: {
            comments: 'Changed'
          }
        }
        # Updating "Comments" in the join team request object
        put :update, params: request_params
        # status code 302: Redirect url
        expect(response.status).to eq 302
      end
    end
  end

  # Testing Decline method
  describe 'Get #decline' do

    context 'when join team request is declined' do
      before(:each) do
        allow(JoinTeamRequest).to receive(:find).and_return(join_team_request2)
        allow(join_team_request2).to receive(:save).and_return(true)
      end
      it "will change status to 'D'" do
        request_params = { action: 'decline' }
        user_session = { user: ta }
        result = get :decline, params: request_params, session: user_session, inv:0
        # status code 302: Redirect url
        expect(result.status).to eq 302
      end
      it 'will redirect to view student teams path' do
        request_params = { action: 'decline' }
        user_session = { user: ta }
        result = get :decline, params: request_params, session: user_session, inv:0
        expect(result).to redirect_to(view_student_teams_path)
      end
    end
  end
  # Testing destroy method
  describe 'destroy method' do
    context 'when valid' do
      it 'will redirect to join team request page' do
        allow(JoinTeamRequest).to receive(:find).and_return(join_team_request2)
        allow(join_team_request2).to receive(:destroy).and_return(true)
        request_params = { action: 'destroy' }
        user_session = { user: ta }
        result = get :destroy, params: request_params, session: user_session
        # status code 302: Redirect url
        expect(result.status).to eq 302
        expect(result).to redirect_to(join_team_requests_url)
      end
    end
  end
  describe '#is_invited?' do
    context 'an invitation has been sent between user1 and user2' do
      it 'returns false' do
        allow(Invitation).to receive(:where).with('from_id = ? and to_id = ? and assignment_id = ? and reply_status = "W"',
                                                  user2.id, user3.id, assignment.id).and_return([Invitation.new])
        expect(Invitation.is_invited?(user2.id, user3.id, assignment.id)).to eq(false)
      end
    end
    context 'an invitation has not been sent between user1 and user2' do
      it 'returns true' do
        allow(Invitation).to receive(:where).with('from_id = ? and to_id = ? and assignment_id = ? and reply_status = "W"',
                                                  user2.id, user3.id, assignment.id).and_return([])
        expect(Invitation.is_invited?(user2.id, user3.id, assignment.id)).to eq(true)
      end
    end
  end
describe '#accept_invitation' do
  context 'a user is not on a team and wishes to join a team with open slots' do
    it 'places the user on a team and returns true' do
      team_id = 0
      allow(TeamsUser).to receive(:team_empty?).with(team_id).and_return(false)
      allow(Invitation).to receive(:remove_users_sent_invites_for_assignment).with(user3.id, assignment.id).and_return(true)
      allow(TeamsUser).to receive(:add_member_to_invited_team).with(user2.id, user3.id, assignment.id).and_return(true)
      allow(Invitation).to receive(:update_users_topic_after_invite_accept).with(user2.id, user3.id, assignment.id).and_return(true)
      allow(MentorManagement).to receive(:assign_mentor)
      expect(Invitation.accept_invitation(team_id, user2.id, user3.id, assignment.id)).to eq(true)
    end
  end
  context 'a user is on a team and wishes to join a team with open slots' do
    it 'removes the user from their previous team, places the user on a team, and returns true' do
      team_id = 1
      allow(TeamsUser).to receive(:team_empty?).with(team_id).and_return(true)
      allow(AssignmentTeam).to receive(:find).with(team_id).and_return(team)
      allow(team).to receive(:assignment).and_return(assignment)
      allow(SignedUpTeam).to receive(:release_topics_selected_by_team_for_assignment).with(team_id, assignment.id).and_return(true)
      allow(AssignmentTeam).to receive(:remove_team_by_id).with(team_id).and_return(true)
      allow(Invitation).to receive(:remove_users_sent_invites_for_assignment).with(user3.id, assignment.id).and_return(true)
      allow(TeamsUser).to receive(:add_member_to_invited_team).with(user2.id, user3.id, assignment.id).and_return(true)
      allow(Invitation).to receive(:update_users_topic_after_invite_accept).with(user2.id, user3.id, assignment.id).and_return(true)
      allow(MentorManagement).to receive(:assign_mentor)
      expect(Invitation.accept_invitation(team_id, user2.id, user3.id, assignment.id)).to eq(true)
    end
  end
  context 'a user is on a team and wishes to join a team without slots' do
    it 'removes the user from their previous team, and returns false' do
      team_id = 1
      allow(TeamsUser).to receive(:team_empty?).with(team_id).and_return(true)
      allow(AssignmentTeam).to receive(:find).with(team_id).and_return(team)
      allow(team).to receive(:assignment).and_return(assignment)
      allow(SignedUpTeam).to receive(:release_topics_selected_by_team_for_assignment).with(team_id, assignment.id).and_return(true)
      allow(AssignmentTeam).to receive(:remove_team_by_id).with(team_id).and_return(true)
      allow(Invitation).to receive(:remove_users_sent_invites_for_assignment).with(user3.id, assignment.id).and_return(true)
      allow(TeamsUser).to receive(:add_member_to_invited_team).with(user2.id, user3.id, assignment.id).and_return(false)
      expect(Invitation.accept_invitation(team_id, user2.id, user3.id, assignment.id)).to eq(false)
    end
  end
  context 'a user is not on a team and wishes to join a team without slots' do
    it 'returns false' do
      team_id = 0
      allow(TeamsUser).to receive(:team_empty?).with(team_id).and_return(false)
      allow(Invitation).to receive(:remove_users_sent_invites_for_assignment).with(user3.id, assignment.id).and_return(true)
      allow(TeamsUser).to receive(:add_member_to_invited_team).with(user2.id, user3.id, assignment.id).and_return(false)
      expect(Invitation.accept_invitation(team_id, user2.id, user3.id, assignment.id)).to eq(false)
    end
  end
end
describe '#remove_users_sent_invites_for_assignment' do
it 'deletes the invitations sent for a given assignment' do
  invites = [Invitation.new, Invitation.new]
  allow(Invitation).to receive(:where).with('from_id = ? and assignment_id = ?', user2.id, assignment.id).and_return(invites)
  expect(Invitation.remove_users_sent_invites_for_assignment(user2.id, assignment.id)).to be(invites)
end
end
describe "#cancel"
    it 'can cancel the invitation sent'
    result = get :cancel, inv_id:user_id
    expect(result).to redirect_to(view_student_teams_path)


    end
end
end
