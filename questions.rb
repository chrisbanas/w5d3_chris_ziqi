require "sqlite3"
require "singleton"

class QuestionsDatabase < SQLite3::Database
    include Singleton
    def initialize
        super('questions.db')
        self.type_translation = true
        self.results_as_hash = true
    end
end

class Questions

    attr_accessor :id, :title, :body, :associated_author_id

    def self.all
        data = QuestionsDatabase.instance.execute("SELECT * FROM questions")
        data.map { |datum| Questions.new(datum) }
    end

    def self.find_by_id(id)
        data = QuestionsDatabase.instance.execute(<<-SQL, id)
        SELECT
            *
        FROM
            questions
        WHERE
            id = ?
        SQL
        return nil unless data.length > 0
        Questions.new(data.first)
    end

    def self.find_by_associated_author_id(associated_author_id)
        data = QuestionsDatabase.instance.execute(<<-SQL, associated_author_id)
        SELECT
            *
        FROM
            questions
        WHERE
            associated_author_id = ?
        SQL
        return nil unless data.length > 0
        data.map { |datum| Questions.new(datum) } # someone may author many posts
    end

    def initialize(options)
        @id = options['id']
        @title = options['title']
        @body = options['body']
        @associated_author_id = options['associated_author_id']
    end

    def author
        Users.find_by_id(associated_author_id)
    end

    def replies
        Replies.find_by_question_id(id)
    end

end

class Users

    attr_accessor :id, :fname, :lname

    def self.all
        data = QuestionsDatabase.instance.execute("SELECT * FROM users")
        data.map { |datum| Users.new(datum) }
    end

    def self.find_by_id(id)
        data = QuestionsDatabase.instance.execute(<<-SQL, id)
        SELECT
            *
        FROM
            users
        WHERE
            id = ?
        SQL
        return nil unless data.length > 0
        Users.new(data.first)
    end

    def self.find_by_name(fname, lname)
        data = QuestionsDatabase.instance.execute(<<-SQL, fname, lname)
        SELECT
            *
        FROM
            users
        WHERE
            fname = ? AND lname = ?
        SQL
        return nil unless data.length > 0
        data.map { |datum| Users.new(datum) } # people may have the same name
    end

    def initialize(options)
        @id = options['id']
        @fname = options['fname']
        @lname = options['lname']
    end


    def authored_questions
        Questions.find_by_associated_author_id(id)
    end

    def authored_replies
        Replies.find_by_user_id(id)
    end



end

class QuestionLikes

    attr_accessor :id, :user_id, :question_id

    def self.all
        data = QuestionsDatabase.instance.execute("SELECT * FROM question_likes")
        data.map { |datum| QuestionLikes.new(datum) }
    end

    def self.find_by_id(id)
        data = QuestionsDatabase.instance.execute(<<-SQL, id)
        SELECT
            *
        FROM
            question_likes
        WHERE
            id = ?
        SQL
        return nil unless data.length > 0
        QuestionLikes.new(data.first)
    end


    def initialize(options)
        @id = options['id']
        @user_id = options['user_id']
        @question_id = options['question_id']
    end
end


class QuestionFollows

    attr_accessor :id, :user_id, :question_id

    def self.all
        data = QuestionsDatabase.instance.execute("SELECT * FROM question_follows")
        data.map { |datum| QuestionFollows.new(datum) }
    end

    def self.find_by_id(id)

        #make an inner join
        data = QuestionsDatabase.instance.execute(<<-SQL, id)
        SELECT
            *
        FROM
            question_follows
        WHERE
            id = ?
        SQL
        return nil unless data.length > 0
        QuestionFollows.new(data.first)
    end

    def self.followers_for_question_id(question_id)
        data = QuestionsDatabase.instance.execute(<<-SQL, question_id)
        SELECT
            user_id
        FROM
            question_follows
        WHERE
            question_id = ?
        SQL
        return nil unless data.length > 0
        QuestionFollows.new(data.first)
    end


    def initialize(options)
        @id = options['id']
        @user_id = options['user_id']
        @question_id = options['question_id']
    end
end


class Replies

    attr_accessor :id, :body, :user_id, :question_id, :parent_reply_id

    def self.all
        data = QuestionsDatabase.instance.execute("SELECT * FROM replies")
        data.map { |datum| Replies.new(datum) }
    end

    def self.find_by_id(id)
        data = QuestionsDatabase.instance.execute(<<-SQL, id)
        SELECT
            *
        FROM
            replies
        WHERE
            id = ?
        SQL
        return nil unless data.length > 0
        Replies.new(data.first)
    end

    def self.find_by_user_id(user_id)
        data = QuestionsDatabase.instance.execute(<<-SQL, user_id)
        SELECT
            *
        FROM
            replies
        WHERE
            user_id = ?
        SQL
        return nil unless data.length > 0
        data.map { |datum| Replies.new(datum) } # users may submit many replies and we would want to get all of them
    end

    def self.find_by_parent_reply_id(parent_reply_id)
        data = QuestionsDatabase.instance.execute(<<-SQL, parent_reply_id)
        SELECT
            *
        FROM
            replies
        WHERE
            parent_reply_id = ?
        SQL
        return nil unless data.length > 0
        Replies.new(data.first)
    end

    def self.find_by_question_id(question_id)
        data = QuestionsDatabase.instance.execute(<<-SQL, question_id)
        SELECT
            *
        FROM
            replies
        WHERE
            question_id = ?
        SQL
        return nil unless data.length > 0
        data.map { |datum| Replies.new(datum) } # this is because we get multiple values back and .first was only returining the first one. There may be more than one reply per question
    end

    def initialize(options)
        @id = options['id']
        @body = options['body']
        @user_id = options['user_id']
        @question_id = options['question_id']
        @parent_reply_id = options['parent_reply_id']
    end

    def author
        Users.find_by_id(user_id)
    end

    def question
        Questions.find_by_id(question_id)
    end

    def parent_reply
        Replies.find_by_id(parent_reply_id)
    end

    def child_replies
        # we want to find the nodes that have the parent_reply id of our current id.
        Replies.find_by_parent_reply_id(id)
    end

end






# p Replies.find_by_user_id(1)
# p Replies.find_by_question_id(2)
a = Users.find_by_id(2)
b = Questions.find_by_id(2)
c = Replies.find_by_id(2)
# p a.authored_questions
# p a.authored_replies
# p b.author
# p b.replies
p c.child_replies
