#
#
# == License:
# Fairmondo - Fairmondo is an open-source online marketplace.
# Copyright (C) 2013 Fairmondo eG
#
# This file is part of Fairmondo.
#
# Fairmondo is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# Fairmondo is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with Fairmondo.  If not, see <http://www.gnu.org/licenses/>.
#
require_relative '../test_helper'

describe UserPolicy do
  include PunditMatcher
  subject { UserPolicy.new(user, resource)  }
  let(:resource) { FactoryGirl.create :user }
  let(:user) { nil }

  describe 'for a visitor' do
    it { subject.must_permit(:show)    }
    it { subject.must_permit(:active_articles)    }
    it { subject.must_permit(:libraries)    }
    it { subject.must_permit(:ratings)    }
    it { subject.must_permit(:profile) }
    it { subject.must_permit(:legal_info)             }
    it { subject.must_deny(:dashboard)             }
    it { subject.must_deny(:inactive_articles)             }
    it { subject.must_deny(:templates)             }
    it { subject.must_deny(:sales)             }
    it { subject.must_deny(:purchases)             }
    it { subject.must_deny(:edit_profile)             }
    it { subject.must_deny(:mass_uploads)             }
  end

  describe 'for a random logged-in user' do
    let(:user) { FactoryGirl.create :user }

    it { subject.must_permit(:show)             }
    it { subject.must_permit(:active_articles)    }
    it { subject.must_permit(:libraries)    }
    it { subject.must_permit(:ratings)    }
    it { subject.must_permit(:profile)          }
    it { subject.must_permit(:legal_info)             }
    it { subject.must_deny(:dashboard)             }
    it { subject.must_deny(:inactive_articles)             }
    it { subject.must_deny(:templates)             }
    it { subject.must_deny(:sales)             }
    it { subject.must_deny(:purchases)             }
    it { subject.must_deny(:edit_profile)             }
    it { subject.must_deny(:mass_uploads)             }
  end

  describe 'for own profile' do
    let(:user) { resource }

    it { subject.must_permit(:show)             }
    it { subject.must_permit(:active_articles)             }
    it { subject.must_permit(:libraries)             }
    it { subject.must_permit(:ratings)             }
    it { subject.must_permit(:profile)             }
    it { subject.must_permit(:dashboard)             }
    it { subject.must_permit(:inactive_articles)             }
    it { subject.must_permit(:legal_info)             }
    it { subject.must_permit(:templates)             }
    it { subject.must_permit(:sales)             }
    it { subject.must_permit(:purchases)             }
    it { subject.must_permit(:edit_profile)             }
    it { subject.must_permit(:mass_uploads)             }
  end
end
