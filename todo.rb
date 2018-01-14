require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/content_for"
require "tilt/erubis"

configure do
  enable :sessions
  set :session_secret, 'secret'
end

helpers do
  def completed?(list)
    total_todos(list) > 0 &&
    count_completed_todos(list) == total_todos(list)
  end

  def total_todos(list)
    list[:todos].size
  end

  def count_completed_todos(list)
    list[:todos].select { |todo| todo[:completed]== true }.size
  end

  def display_completed_todos(list)
    size = total_todos(list)
    completed = count_completed_todos(list)
    "#{completed}/#{size}"
  end

  def list_class(list)
    "complete" if completed?(list)
  end

  def sort_lists_by_completed!(lists)
    lists.sort_by! { |list| completed?(list) ? 1 : 0 }
  end

  def sort_todos_by_completed!(todos)
    todos.sort_by! { |todo| todo[:completed] == true ? 1 : 0 }
  end


end

before do
  session[:lists] ||= []
end

get "/" do
  redirect "/lists"
end

# Display lists
get "/lists" do
  @lists = session[:lists]
  erb :lists, layout: :layout
end

get "/lists/new" do
  erb :new_list, layout: :layout
end

# Return an error message if the name is invalid. Return nil if name is valid.
def error_for_list_name(name)
  if !(1..100).cover? name.size
    "The list must be between 1 and 100 characters"
  elsif session[:lists].any? { |list| list[:name] == name}
    "The list name must be unique"
  end
end

def error_for_todo(todo)
  if todo.size == 0
    "You must enter a todo"
  end
end


# Create a new list
post "/lists" do
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    session[:lists] << { name: list_name, todos: [] }
    session[:success] = "The list has been created"
    redirect "/lists"
  end
end

get "/lists/:list_id" do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]
  @todos = @list[:todos]

  erb :list, layout: :layout
end

# Edit an existing todo list
get "/lists/:id/edit" do
  id = params[:id].to_i
  @list = session[:lists][id]

  erb :edit_list, layout: :layout
end

# Updating an existing todo list
post "/lists/:id" do
  list_name = params[:list_name].strip
  @id = params[:id].to_i
  @list = session[:lists][@id]

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :edit_list, layout: :layout
  else
    @list[:name] = list_name
    session[:success] = "The list has been updated"
    redirect "/lists"
  end
end

# Delete a todo list
post "/lists/:id/delete" do
  id = params[:id].to_i
  session[:lists].delete_at(id)
  session[:success] = "List successfully deleted"
  redirect "/lists"
end

# Add a new todo to a list
post "/lists/:list_id/todos" do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]
  todo = params[:todo].strip
  @todos = @list[:todos]


  error = error_for_todo(todo)
  if error
    session[:error] = error
    erb :list, layout: :layout
  else
    @list[:todos] << { name: todo, completed: false }
    session[:success] = "Todo added"
    redirect "/lists/#{@list_id}"
  end
end

# Deleteing a todo
post "/lists/:list_id/todos/:todo_id/delete" do
  list_id = params[:list_id].to_i
  list = session[:lists][list_id]
  todo_id = params[:todo_id].to_i
  list[:todos].delete_at(todo_id)
  session[:success] = "Todo deleted"
  redirect "lists/#{list_id}"
end

# Check off a completed task

post '/lists/:list_id/todos/:todo_id' do
  list_id = params[:list_id].to_i
  todo_id = params[:todo_id].to_i
  list = session[:lists][list_id]

  is_completed = params[:complete] == "true"
  list[:todos][todo_id][:completed] = is_completed
  session[:success] = "Todo status altered"
  redirect "lists/#{list_id}"
end

post '/lists/:list_id/completed' do
  list_id = params[:list_id].to_i
  list = session[:lists][list_id]
    list[:todos].each do |todo|
      todo[:completed] = true
    end
  session[:success] = "All todos have been completed. Go have a cup of tea!"
  redirect "lists/#{list_id}"
end
