import { useUsers, useCreateUser } from "@/hooks/use-users";
import Layout from "@/components/layout";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
  DialogDescription,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { useState } from "react";
import { Plus, UserPlus } from "lucide-react";
import { format } from "date-fns";

export default function AdminEmployees() {
  const { data: users } = useUsers();
  const createUser = useCreateUser();
  const deleteUser = useDeleteUser();
  const updateUser = useUpdateUser();
  const [open, setOpen] = useState(false);
  const [editingUser, setEditingUser] = useState<any>(null);

  // Form State
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [fullName, setFullName] = useState("");
  const [role, setRole] = useState("employee");

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (editingUser) {
      await updateUser.mutateAsync({
        id: editingUser.id,
        username,
        fullName,
        role: role as any,
        ...(password ? { password } : {})
      });
    } else {
      await createUser.mutateAsync({
        username,
        password,
        fullName,
        role: role as "admin" | "employee"
      });
    }
    setOpen(false);
    resetForm();
  };

  const resetForm = () => {
    setEditingUser(null);
    setUsername("");
    setPassword("");
    setFullName("");
    setRole("employee");
  };

  const handleEdit = (user: any) => {
    setEditingUser(user);
    setUsername(user.username);
    setPassword("");
    setFullName(user.fullName);
    setRole(user.role);
    setOpen(true);
  };

  const handleDelete = async (id: number) => {
    if (confirm("¿Estás seguro de que deseas eliminar este usuario?")) {
      await deleteUser.mutateAsync(id);
    }
  };

  return (
    <Layout>
      <div className="space-y-8">
        <div className="flex items-center justify-between">
          <h1 className="text-3xl font-bold tracking-tight">Empleados</h1>
          
          <Dialog open={open} onOpenChange={(val) => { setOpen(val); if(!val) resetForm(); }}>
            <DialogTrigger asChild>
              <Button onClick={resetForm}>
                <UserPlus className="mr-2 h-4 w-4" /> Nuevo Empleado
              </Button>
            </DialogTrigger>
            <DialogContent>
              <DialogHeader>
                <DialogTitle>{editingUser ? "Editar Usuario" : "Crear Nuevo Usuario"}</DialogTitle>
                <DialogDescription>
                  {editingUser ? "Modifica los datos del usuario." : "Agrega un nuevo empleado o administrador al sistema."}
                </DialogDescription>
              </DialogHeader>
              <form onSubmit={handleSubmit} className="space-y-4 pt-4">
                <div className="space-y-2">
                  <Label>Nombre Completo</Label>
                  <Input 
                    value={fullName}
                    onChange={e => setFullName(e.target.value)}
                    required
                  />
                </div>
                <div className="space-y-2">
                  <Label>Usuario</Label>
                  <Input 
                    value={username}
                    onChange={e => setUsername(e.target.value)}
                    required
                  />
                </div>
                <div className="space-y-2">
                  <Label>Contraseña {editingUser && "(dejar en blanco para no cambiar)"}</Label>
                  <Input 
                    type="password"
                    value={password}
                    onChange={e => setPassword(e.target.value)}
                    required={!editingUser}
                  />
                </div>
                <div className="space-y-2">
                  <Label>Rol</Label>
                  <Select value={role} onValueChange={setRole}>
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="employee">Empleado</SelectItem>
                      <SelectItem value="admin">Administrador</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
                <Button type="submit" className="w-full" disabled={createUser.isPending || updateUser.isPending}>
                  {createUser.isPending || updateUser.isPending ? "Procesando..." : (editingUser ? "Actualizar Usuario" : "Crear Usuario")}
                </Button>
              </form>
            </DialogContent>
          </Dialog>
        </div>

        <div className="rounded-md border bg-card shadow-sm overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="bg-muted/50 border-b">
                <tr className="text-left">
                  <th className="p-4 font-medium text-muted-foreground">Nombre</th>
                  <th className="p-4 font-medium text-muted-foreground">Usuario</th>
                  <th className="p-4 font-medium text-muted-foreground">Rol</th>
                  <th className="p-4 font-medium text-muted-foreground">Creado</th>
                  <th className="p-4 font-medium text-muted-foreground">Acciones</th>
                </tr>
              </thead>
              <tbody>
                {users?.map((user) => (
                  <tr key={user.id} className="border-b last:border-0 hover:bg-muted/20 transition-colors">
                    <td className="p-4 font-medium">{user.fullName}</td>
                    <td className="p-4 text-muted-foreground">{user.username}</td>
                    <td className="p-4">
                      <span className={`px-2 py-1 rounded-full text-xs font-medium border ${
                        user.role === 'admin' 
                          ? 'bg-purple-100 text-purple-700 border-purple-200' 
                          : 'bg-blue-100 text-blue-700 border-blue-200'
                      }`}>
                        {user.role === 'admin' ? 'Administrador' : 'Empleado'}
                      </span>
                    </td>
                    <td className="p-4 text-muted-foreground">
                      {user.createdAt ? format(new Date(user.createdAt), 'dd/MM/yyyy') : '-'}
                    </td>
                    <td className="p-4 flex gap-2">
                       <Button variant="ghost" size="sm" onClick={() => handleEdit(user)}>Editar</Button>
                       <Button variant="ghost" size="sm" className="text-red-600" onClick={() => handleDelete(user.id)}>Eliminar</Button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </Layout>
  );
}
